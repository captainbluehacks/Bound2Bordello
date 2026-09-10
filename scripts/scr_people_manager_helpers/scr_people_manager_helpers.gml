/// @description Creates helper functions for the People manager. Should only be called from obj_people_manager.
function __obj_people_manager_helpers(){

	/// @description Load specified backgrounds and return an optionally shuffled list
	/// @param _json_file The json file to be read.
	/// @param _shuffle  Whether to shuffle the dataset before returning.
	/// @return An array or struct depending on what the top level entry in the json file is.
	function scr_load_json_file(_json_file, _shuffle=false) {
	
		var _buffer = buffer_load(_json_file);
		var _json_string = buffer_read(_buffer, buffer_string);
		buffer_delete(_buffer);
		
		var _entries = json_parse(_json_string);
		
		if (_shuffle) {
			return array_shuffle(_entries);
		}
		else {
			return (_entries);
		}
	}
	
	///@description Return the name of a client from the pool. The name is deleted from the pool.
	///@return A string with the name. 
	function scr_get_client_name() {
		
		var _list = struct_get(name_pool, "client");
		
		if (array_length(_list) == 0) {
			// Somehow we've run out of names, we'll just have to reuse them.
			name_pool = scr_load_json_file("names.json");
			_list = struct_get(name_pool, "client");
		}
		
		var _idx = irandom(array_length(_list) - 1);
		var _name = _list[_idx];
		array_delete(_list, _idx, 1);
		
		return _name;
	}
		
	///@description Return three potential names for a minion.
	///@return An array with three names. 
	function scr_get_minion_name() {
		
		var _all_types = struct_get(name_pool, "minion");
		var _keys = struct_get_names(_all_types);
		
		if (array_length(_keys) < 3) {
			// We don't have enough name types to offer 3 different ones.
			// We'll reload the names. Duplicates might be boring,
			// but better than running out or crashing.
			name_pool = scr_load_json_file("names.json");
			_all_types = struct_get(name_pool, "minion");
			_keys = struct_get_names(_all_types);
		}
		
		var _types = array_shuffle(struct_get_names(_all_types));
		
		var _names = [];
		
		for (var _i = 0; _i < 3; _i++) {
			var _current_list = struct_get(_all_types, _types[_i]);
		
			var _idx = irandom(array_length(_current_list) - 1);
			array_push(_names, _current_list[_idx]);
			array_delete(_current_list, _idx, 1);
			
			if (array_length(_current_list) == 0) {
				// We've run out of this key, remove the type.
				struct_remove(_all_types, _types[_i]);
			}
		}
		
		return _names;
	}
	
	
	/// @description Return a list of clients to be added to the pool for this season.
	/// @param _pool  The pool from which to return clients: "village", "city" etc  
	/// @return array The list of clients
	function scr_get_new_clients(_pool) {
		var _clients = [];
		var _pool_def = scr_load_json_file("client_pools.json");

		if (struct_exists(_pool_def, _pool)) {
			var _definition = struct_get(_pool_def, _pool);
			
			var _background = scr_load_json_file(_definition.source, true);
			
			// Limit clients to count of backgrounds, just in case someone edits client_pools.json
			var _count = min(_definition.clients, array_length(_background));
			
			for (var _i = 0; _i < _count; _i++) {
				var _inst = instance_create_layer(0, 0, people_layer.entities, obj_client);
				
				// First let's hide the client.
				_inst.visible = false;
				
				// Then setup name, backstory and tags
				_inst.name = scr_get_client_name();
				_inst.backstory = _background[_i].text;
				_inst.tags = array_concat(_inst.tags, _background[_i].tags);
				
				array_push(_clients, _inst);
			}
		}
		
		return _clients;
	}
}
