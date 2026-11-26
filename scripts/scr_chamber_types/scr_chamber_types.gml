/// @description Load all chamber type definitions at game start.
function scr_load_chamber_types() {
		
	var _chamber_type_defs = {data : [], lookup : {}};
	
	var _files = [
		"chamber_types/succubus.json"
	];
    
	for (var i = 0; i < array_length(_files); i++) {
		var _buffer = buffer_load(_files[i]);
		var _json_string = buffer_read(_buffer, buffer_string);
		buffer_delete(_buffer);
        
		var _entries = json_parse(_json_string);
		for (var j = 0; j < array_length(_entries); j++) {
		    // Tag each entry with its source ally for potential gating later
		    _entries[j].source_ally = scr_filename_to_ally(_files[i]);
            
		    var _idx = array_length(_chamber_type_defs.data);
		    array_push(_chamber_type_defs.data, _entries[j]);
			var _type = _entries[j].type;
			struct_set(_chamber_type_defs.lookup, _type, _idx);
		}
	}
	
	return _chamber_type_defs ;
}


/// @description Look up a chamber type definition by its type string.
/// @param {string} _type_string
/// @return {map|undefined} The full type definition map.
function scr_get_chamber_type(_type_string) {
		
	if (!struct_exists(obj_mansion_init.chamber_type_defs.lookup, _type_string)) return undefined;
		
	var _idx = struct_get(obj_mansion_init.chamber_type_defs.lookup, _type_string);
	return obj_mansion_init.chamber_type_defs.data[_idx];
}



/// @description Extract the ally name from a datafile path (the filename stem).
/// e.g. "chamber_types/succubus.json" returns "succubus".
/// @param {string} _path Path to the JSON file, using forward slashes.
/// @return {string} The filename without its extension.
function scr_filename_to_ally(_path) {
	// "chamber_types/succubus.json" → "succubus"
	var _parts = string_split(_path, "/");
	var _fname = string_split(_parts[array_length(_parts) - 1], ".")[0];
	return _fname;
}

/// @description Get the list of tags a chamber type carries (empty if it has none).
/// @param {string} _type_string
/// @return {ds_list} List of tag strings for this type.
function scr_get_chamber_tags(_type_string) {
	var _def = scr_get_chamber_type(_type_string);
	if (_def == undefined || !struct_exists(_def,"tags")) return ds_list_create();
    
	var _tags = ds_list_create();
	var _tag_array = _def.tags;
	for (var i = 0; i < array_length(_tag_array); i++) {
		ds_list_add(_tags, _tag_array[i]);
	}
	return _tags;
}
	
// Upgrades
/// @description Load all upgrade definitions at game start.
function scr_load_upgrades() {
	
	var _upgrade_defs = {data : [], lookup : {}};
	
	var _files = [
		"upgrades/succubus.json"
		// Future ally upgrade files go here, e.g. "upgrades/<ally>.json".
	];
    
	for (var i = 0; i < array_length(_files); i++) {
		var _buffer = buffer_load(_files[i]);
		var _json_string = buffer_read(_buffer, buffer_string);
		buffer_delete(_buffer);
        
		var _entries = json_parse(_json_string);
		for (var j = 0; j < array_length(_entries); j++) {
		    // Tag each entry with its source ally for potential gating later
		    _entries[j].source_ally = scr_filename_to_ally(_files[i]);
            
		    var _idx = array_length(_upgrade_defs.data);
		    array_push(_upgrade_defs.data, _entries[j]);
			struct_set(_upgrade_defs.lookup, _entries[j].id, _idx);
		}
	}
	
	return _upgrade_defs;
}

/// @description Look up an upgrade definition by its ID.
/// @param {string} _upgrade_id
/// @return {map|undefined} The full upgrade definition map.
function scr_get_upgrade(_upgrade_id) {
	if (!struct_exists(obj_mansion_init.upgrade_defs.lookup, _upgrade_id)) return undefined;
	
	var _idx = struct_get(obj_mansion_init.upgrade_defs.lookup, _upgrade_id);
	return obj_mansion_init.upgrade_defs.data[_idx];
}

