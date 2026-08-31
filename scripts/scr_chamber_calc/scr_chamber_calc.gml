/// @description Calculate a single chamber's total contribution + breakdown.
/// @param {instance} _chamber The obj_chamber instance.
/// @return {map} { total: map, lines: array }
function scr_calculate_chamber(_chamber) {
    var _type_def = scr_get_chamber_type(_chamber.chamber_type);
    if (_type_def == undefined) return { total: {}, lines: [] };
    
	    // --- Prerequisite gate ---
    var _active = true;
    var _reason = "";
    
    if (map_exists(_type_def, "requires")) {
        var _req = _type_def.requires;
        
        if (_req.minion && !(_chamber.minion != noone && is_instance(_chamber.minion))) {
            _active = false;
            _reason = "No minion assigned";
        }
        
        if (_active && _req.client && !(array_length(_chamber.client) > 0)) {
            _active = false;
            _reason = "No client present";
        }
    }
    
    // If gated out, return immediately with a single explanatory line
    if (!_active) {
        return {
            total: {},
            lines: [{ label: "inactive", detail: _reason, effects: {}, active: false }],
            active: false,
            reason: _reason
        };
    }
	
    var _total = {};       // accumulated resource totals
    var _lines = [];       // breakdown for UI
    
    // --- Base contribution (always applies) ---
    var _base = _type_def.base;
    var _base_keys = map_get_keys(_base);
    for (var i = 0; i < array_length(_base_keys); i++) {
        var _res = _base_keys[i];
        _total[_res] = (_total.exists(_res) ? _total[_res] : 0) + _base[_res];
    }
    
    // Record the base line for UI
    array_push(_lines, {
        label: "Base",
        detail: _type_def.display_name + " base output",
        effects: _base,
        active: true
    });
    
    // --- Bonus rules ---
    var _bonuses = _type_def.bonuses;
    for (var b = 0; b < array_length(_bonuses); b++) {
        var _rule = _bonuses[b];
        
        // Evaluate the condition
        var _result = scr_eval_condition(_chamber, _rule.condition);
        
        if (_result == false) continue;  // rule not triggered
        
        // Determine the effect magnitude
        var _effects;
        if (map_exists(_rule, "effects_per_match")) {
            // Scaled: multiply effects by the integer result
            _effects = {};
            var _keys = map_get_keys(_rule.effects_per_match);
            for (var k = 0; k < array_length(_keys); k++) {
                _effects[_keys[k]] = _rule.effects_per_match[_keys[k]] * _result;
            }
        } else {
            _effects = _rule.effects;
        }
        
        // Accumulate into total
        var _eff_keys = map_get_keys(_effects);
        for (var k = 0; k < array_length(_eff_keys); k++) {
            var _res = _eff_keys[k];
            _total[_res] = (_total.exists(_res) ? _total[_res] : 0) + _effects[_res];
        }
        
        // Record for UI breakdown
        array_push(_lines, {
            label: _rule.id,
            detail: _rule.description,
            effects: _effects,
            active: true
        });
    }
    
	// --- Upgrade contribution (if installed) ---
    if (_chamber.upgrade_id != noone && _chamber.upgrade_id != "") {
        var _upg_def = scr_get_upgrade(_chamber.upgrade_id);
        
        if (_upg_def != undefined) {
            // Verify compatibility (safety check; should be enforced at assignment time too)
            var _compatible = false;
            for (var c = 0; c < array_length(_upg_def.compatible_types); c++) {
                if (_upg_def.compatible_types[c] == "*" || 
                    _upg_def.compatible_types[c] == _chamber.chamber_type) {
                    _compatible = true;
                    break;
                }
            }
            
            if (_compatible) {
                // Add flat effects
                var _eff_keys = map_get_keys(_upg_def.effects);
                for (var k = 0; k < array_length(_eff_keys); k++) {
                    var _res = _eff_keys[k];
                    _total[_res] = (_total.exists(_res) ? _total[_res] : 0) + _upg_def.effects[_res];
                }
                
                // Record for UI breakdown
                array_push(_lines, {
                    label: "upgrade_" + _chamber.upgrade_id,
                    detail: _upg_def.display_name,
                    effects: _upg_def.effects,
                    active: true
                });
            }
        }
    }
	
	
    return { total: _total, lines: _lines, active: _active };
}


/// @description Sum contributions across ALL chambers (nightly earnings).
/// @return {map} Total resource map summed over all chambers.
function scr_calculate_night_earnings() {
    var _summary = {earnings : {}, active_rooms: [], inactive_rooms: []};
    
    // Iterate the mansion_map grid, collecting unique chamber instances
    var _seen = ds_set_create();
    var _w = ds_grid_width(global.mansion_map);
    var _h = ds_grid_height(global.mansion_map);
    
    for (var _x = 0; _x < _w; _x++) {
        for (var _y = 0; _y < _h; _y++) {
            var _inst = ds_grid_get(global.mansion_map, _x, _y);
            if (_inst == -1) continue;
            if (!is_instance(_inst)) continue;
            if (ds_set_find(_seen, _inst) != -1) continue;  // skip duplicates from multi-cell rooms
            ds_set_add(_seen, _inst);
            
            var _result = scr_calculate_chamber(_inst);
			
			if (_result.active) {
				array_push(_summary.active_rooms, { chamber: _inst, result: _result });
			} else {
				array_push(_summary.inactive_rooms, { chamber: _inst, reason: _result.reason });
			}
				
            var _keys = map_get_keys(_result.total);
            for (var i = 0; i < array_length(_keys); i++) {
                var _res = _keys[i];
                _summary.earnings[_res] = (_summary.earnings.exists(_res) ? _summary.earnings[_res] : 0) + _result.total[_res];
            }
        }
    }
    
    ds_set_destroy(_seen);
    return _summary;
}


/// @description Evaluate a condition object against a chamber.
/// @param {instance} _chamber
/// @param {map} _cond  The condition map from JSON.
/// @return {bool|int} true/false for boolean conditions, int for count conditions.
function scr_eval_condition(_chamber, _cond) {
    switch (_cond.type) {
        
        case "adjacent_room_type":
            return scr_check_adjacent(_chamber, _cond);
            
        case "count_tag_on_floor":
            return scr_count_tag_on_floor(_chamber, _cond.tag, _cond.max);
            
        case "minion_assigned":
            return (_chamber.minion != no && is_instance(_chamber.minion));
            
        case "floor_is":
            return (_chamber.floor == _cond.floor);
            
        // Add more condition types here as needed...
        
        default:
            show_debug_message("Unknown chamber condition type: " + string(_cond.type));
            return false;
    }
}
