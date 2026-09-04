/// @description Calculate a single chamber's total contribution + breakdown.
/// @param {instance} _chamber The obj_chamber instance.
/// @param {struct} [_type_def] Optional: A custom type definition (use this for testing!)
/// @return {map} { total: map, lines: array }
function scr_calculate_chamber(_chamber, _type_def = undefined) {
    // --- REFACTOR: Dependency Injection ---
    // If we passed a _type_def (from a test), use it. 
    // Otherwise, look up the real one from the game data.
    var _actual_type_def = is_undefined(_type_def) ? scr_get_chamber_type(_chamber.chamber_type) : _type_def;
    
    if (_actual_type_def == undefined) return { total: {}, lines: [], active: false };
    
    // 1. Check if the chamber is actually running (Prerequisites)
    var _gate = scr_chamber_check_prerequisites(_actual_type_def, _chamber);
    if (!_gate.active) {
        return {
            total: {},
            lines: [{ label: "inactive", detail: _gate.reason, effects: {}, active: false }],
            active: false,
            reason: _gate.reason
        };
    }

    var _total = {}; 
    var _lines = []; 
    
    // 2. Process the three stages of production
    scr_chamber_apply_base(_actual_type_def, _total, _lines);
    scr_chamber_apply_bonuses(_chamber, _actual_type_def, _total, _lines);
    scr_chamber_apply_upgrades(_chamber, _total, _lines);
    
    return { total: _total, lines: _lines, active: true };
}



function scr_chamber_check_prerequisites(_type_def, _chamber) {
    if (!struct_exists(_type_def, "requires")) return { active: true };
    
    var _req = _type_def.requires;
    if (_req.minion && !(_chamber.minion != noone && is_instance(_chamber.minion))) {
        return { active: false, reason: "No minion assigned" };
    }
    if (_req.client && !(array_length(_chamber.client) > 0)) {
        return { active: false, reason: "No client present" };
    }
    
    return { active: true };
}


function scr_chamber_apply_base(_type_def, _total, _lines) {
	
	// Safety check
	if (!struct_exists(_type_def, "base")) return;
	
    var _base = _type_def.base;
    scr_chamber_sum_resources(_total, _base);
    
    array_push(_lines, {
        label: "Base",
        detail: _type_def.display_name + " base output",
        effects: _base,
        active: true
    });
}


function scr_chamber_apply_bonuses(_chamber, _type_def, _total, _lines) {
    // SAFETY CHECK: If there are no bonuses defined for this type, just exit early.
    if (!struct_exists(_type_def, "bonuses")) return;

    var _bonuses = _type_def.bonuses;
    for (var b = 0; b < array_length(_bonuses); b++) {
        var _rule = _bonuses[b];
        var _result = scr_eval_condition(_chamber, _rule.condition);
        if (_result == false) continue;

        // Calculate effect magnitude (scaled or flat)
        var _effects;
        if (struct_exists(_rule, "effects_per_match")) {
            _effects = {};
            var _keys = variable_struct_get_names(_rule.effects_per_match);
            for (var k = 0; k < array_length(_keys); k++) {
                var _key = _keys[k];
                _effects[$ _key] = _rule.effects_per_match[$ _key] * _result;
            }
        } else {
            _effects = _rule.effects;
        }

        scr_chamber_sum_resources(_total, _effects);
        array_push(_lines, { label: _rule.id, detail: _rule.description, effects: _effects, active: true });
    }
}



function scr_chamber_apply_upgrades(_chamber, _total, _lines) {
    if (_chamber.upgrade_id == noone || _chamber.upgrade_id == "") return;
    
    var _upg_def = scr_get_upgrade(_chamber.upgrade_id);
    if (_upg_def == undefined) return;

    // Compatibility check
    var _compatible = false;
    for (var c = 0; c < array_length(_upg_def.compatible_types); c++) {
        if (_upg_def.compatible_types[c] == "*" || _upg_def.compatible_types[c] == _chamber.chamber_type) {
            _compatible = true;
            break;
        }
    }

    if (_compatible) {
        scr_chamber_sum_resources(_total, _upg_def.effects);
        array_push(_lines, {
            label: "upgrade_" + _chamber.upgrade_id,
            detail: _upg_def.display_name,
            effects: _upg_def.effects,
            active: true
        });
    }
}


/// @description Adds values from a source struct into a total struct.
function scr_chamber_sum_resources(_total, _source) {
    var _keys = variable_struct_get_names(_source);
    for (var i = 0; i < array_length(_keys); i++) {
        var _res = _keys[i];
        _total[$ _res] = (struct_exists(_total, _res) ? _total[$ _res] : 0) + _source[$ _res];
    }
}


/// @description Sum contributions across ALL chambers (nightly earnings).
/// @return {map} Total resource map summed over all chambers.
function scr_calculate_night_earnings() {
    var _summary = {earnings : {}, active_rooms: [], inactive_rooms: []};
    
    // Use a DS Map as a set to track unique chamber instances
    var _seen = ds_map_create(); 
    var _w = ds_grid_width(global.mansion_map);
    var _h = ds_grid_height(global.mansion_map);
    
    for (var _x = 0; _x < _w; _x++) {
        for (var _y = 0; _y < _h; _y++) {
            var _inst = ds_grid_get(global.mansion_map, _x, _y);
            if (_inst == -1 || !is_instance(_inst)) continue;
            if (ds_map_exists(_seen, _inst)) continue; 
            ds_map_add(_seen, _inst, true);
            
            var _result = scr_calculate_chamber(_inst);
            
            if (_result.active) {
                array_push(_summary.active_rooms, { chamber: _inst, result: _result });
            } else {
                array_push(_summary.inactive_rooms, { chamber: _inst, reason: _result.reason });
            }
            
            // --- REPLACED LOOP WITH UTILITY FUNCTION ---
            scr_chamber_sum_resources(_summary.earnings, _result.total);
        }
    }
    
    ds_map_destroy(_seen);
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
