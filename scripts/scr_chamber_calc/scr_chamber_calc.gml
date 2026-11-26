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



/// @description Check whether a chamber is running tonight (minion/client requirements).
/// @param {map} _type_def The chamber type definition.
/// @param {instance} _chamber The obj_chamber instance.
/// @return {map} { active: bool, reason?: string } — reason only when inactive.
function scr_chamber_check_prerequisites(_type_def, _chamber) {
    if (!struct_exists(_type_def, "requires")) return { active: true };
    
    var _req = _type_def.requires;
    if (_req.minion && array_length(_chamber.minions) == 0) {
        return { active: false, reason: "No minion assigned" };
    }
    if (_req.client && !(array_length(_chamber.clients) > 0)) {
        return { active: false, reason: "No client present" };
    }
    
    return { active: true };
}


/// @description Add the type's base output to the running total and breakdown.
/// Mutates _total and _lines in place; no return.
/// @param {map} _type_def The chamber type definition.
/// @param {map} _total Accumulated resource totals (mutated).
/// @param {array} _lines Breakdown lines array (appended to).
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


/// @description Evaluate the type's bonus rules against the chamber and add any
/// matching effects (flat or per-match scaled) to the totals. Mutates _total and
/// _lines in place; no return.
/// @param {instance} _chamber The obj_chamber instance.
/// @param {map} _type_def The chamber type definition.
/// @param {map} _total Accumulated resource totals (mutated).
/// @param {array} _lines Breakdown lines array (appended to).
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



/// @description If the chamber has a compatible upgrade installed, add its effects
/// to the totals. Mutates _total and _lines in place; no return.
/// @param {instance} _chamber The obj_chamber instance.
/// @param {map} _total Accumulated resource totals (mutated).
/// @param {array} _lines Breakdown lines array (appended to).
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
/// @param {map} _total Accumulated resource totals (mutated).
/// @param {map} _source Resource effects to add in.
function scr_chamber_sum_resources(_total, _source) {
    var _keys = variable_struct_get_names(_source);
    for (var i = 0; i < array_length(_keys); i++) {
        var _res = _keys[i];
        _total[$ _res] = (struct_exists(_total, _res) ? _total[$ _res] : 0) + _source[$ _res];
    }
}


/// @description Sum contributions across ALL chambers (nightly earnings).
/// Two passes per spec: 1) per-chamber totals, 2) aura pass — each chamber with an
/// `aura` applies it once per unique adjacent chamber's accumulated total and to the
/// grand total. Independent of the adder's own prerequisites; never applies to itself.
/// @return {map} { earnings: map, active_rooms: array, inactive_rooms: array }
function scr_calculate_night_earnings() {
    var _summary = {earnings : {}, active_rooms: [], inactive_rooms: []};
    
    // Use a DS Map as a set to track unique chamber instances (multi-cell rooms)
    var _seen = ds_map_create(); 
    var _results = ds_map_create();   // chamber instance -> its result map
    var _chambers = [];               // unique chambers, in scan order
    
    var _w = ds_grid_width(global.mansion_map);
    var _h = ds_grid_height(global.mansion_map);
    
    // --- Pass 1: per-chamber totals ---
    for (var _x = 0; _x < _w; _x++) {
        for (var _y = 0; _y < _h; _y++) {
            var _inst = ds_grid_get(global.mansion_map, _x, _y);
            if (_inst == -1) continue;
            if (ds_map_exists(_seen, _inst)) continue; 
            ds_map_add(_seen, _inst, true);
            
            array_push(_chambers, _inst);
            
            var _result = scr_calculate_chamber(_inst);
            ds_map_add(_results, _inst, _result);
            
            if (_result.active) {
                array_push(_summary.active_rooms, { chamber: _inst, result: _result });
            } else {
                array_push(_summary.inactive_rooms, { chamber: _inst, reason: _result.reason });
            }
            
            scr_chamber_sum_resources(_summary.earnings, _result.total);
        }
    }
    
    // --- Pass 2: aura (adders) ---
    for (var i = 0; i < array_length(_chambers); i++) {
        var _adder = _chambers[i];
        
        var _type_def = scr_get_chamber_type(_adder.chamber_type);
        if (_type_def == undefined || !struct_exists(_type_def, "aura")) continue;
        
        var _aura = _type_def.aura;
        var _adj = scr_get_adjacent_chambers(_adder); // already deduped
        
        for (var j = 0; j < array_length(_adj); j++) {
            var _target = _adj[j];
            if (!ds_map_exists(_results, _target)) continue;
            var _t_result = ds_map_find_value(_results, _target);
            
            // Add to the target's accumulated total + breakdown, and to the grand total.
            scr_chamber_sum_resources(_t_result.total, _aura);
            array_push(_t_result.lines, {
                label: "aura_" + _adder.chamber_type,
                detail: "Aura from " + _type_def.display_name,
                effects: _aura,
                active: true
            });
            scr_chamber_sum_resources(_summary.earnings, _aura);
        }
    }
    
    ds_map_destroy(_seen);
    ds_map_destroy(_results);
    return _summary;
}


/// @description True if any occupied minion slot in this chamber carries the tag.
/// Empty slots (noone) are skipped, so multi-slot rooms work as they land.
/// @param {instance} _chamber The obj_chamber instance.
/// @param {string} _tag Tag to look for on the minions' tag arrays.
function scr_chamber_minion_has_tag(_chamber, _tag) {
    for (var i = 0; i < array_length(_chamber.minions); i++) {
        var _m = _chamber.minions[i];
        if (_m == noone || !instance_exists(_m)) continue;
        if (array_contains(_m.tags, _tag)) return true;
    }
    return false;
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
            // Guard max the same way as count_adjacent_tag: data may omit it.
            var _floor_cap = struct_exists(_cond, "max") ? _cond.max : noone;
            return scr_count_tag_on_floor(_chamber, _cond.tag, _floor_cap);
            
        case "count_adjacent_tag":
            // Count condition: unique adjacent chambers carrying the tag (effective
            // tags), capped at optional max. Feeds effects_per_match collectors.
            var _cap = struct_exists(_cond, "max") ? _cond.max : noone;
            return scr_count_adjacent_tag(_chamber, _cond.tag, _cap);
            
        case "minion_assigned":
            return (array_length(_chamber.minions) > 0);
            
        case "minion_has_tag":
            // Boolean: any occupied minion slot carries the tag.
            return scr_chamber_minion_has_tag(_chamber, _cond.tag);
            
        case "clients_present_count":
            // Count condition: number of clients in this chamber tonight.
            // Used with effects_per_match by scalable rooms (Bar, Lobby, …).
            return array_length(_chamber.clients);
            
        case "floor_is":
            return (_chamber.floor == _cond.floor);
            
        case "upgrade_present":
            // Boolean: a specific upgrade is installed in this chamber.
            return (_chamber.upgrade_id == _cond.upgrade_id);
            
        // Add more condition types here as needed...
        
        default:
            show_debug_message("Unknown chamber condition type: " + string(_cond.type));
            return false;
    }
}
