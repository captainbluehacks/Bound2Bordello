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
	
	/// @description Move the given minion to the given chamber if allowed.
	/// @param_pool _minion  The minion object we want to move.
	/// @param_pool _chamber The chamber object we want to add the minion to.
	/// @return boolean True if the minion was moved.
	function scr_move_minion(_minion, _chamber) {
		// Check if types are valid
		if (_minion.object_index != obj_minion || _chamber.object_index != obj_chamber) {
			show_debug_message("Minion or Chamber not found in scr_move_minion");
			show_debug_message("Minion was: " + string(_minion) + " of type " + asset_get_type(_minion));
			show_debug_message("Chamber was: " + string(_chamber) + " of type " + asset_get_type(_chamber));
			return false;
		}
		
		// First check if there's space.
		if (array_length(_chamber.minions) + 1 > _chamber.max_minions) {
			show_debug_message("No room in " + _chamber + " for " + string(_minion.name));
			return false;
		}
		
		// Add the minion to the chamber and vice-versa
		_minion.current_chamber = _chamber;
		array_push(_chamber.minions, _minion);
		
		// Set Minion's new target coordinates
		
		// The x coord we're given is the middle of the position. We need to move left by half our width.
		_minion.target_x = _chamber.get_person_position(_minion, "x") - _minion.sprite_width / 2;
		
		// The y coord we're given is to the floor. We need to move up by the sprites height.
		_minion.target_y = _chamber.get_person_position(_minion, "y") - _minion.sprite_height;
		
		return true;
	}
	
	/// @description Creates a minion to represent the player and their best friend.
	/// @return array containing the two new obj_minion objects.
	function scr_create_first_minions() {
		
		var _new_names = scr_get_minion_name();
		
		// Create the player
		var _pc = instance_create_layer(0, 0, people_layer.entities, obj_minion);
		_pc.name = _new_names[0] ;
		_pc.guest_name = scr_get_client_name();
		_pc.is_pc = true;
		_pc.tags = ["succubus"];
		_pc.backstory = "A foolish young man that made a deal with a demon.";
		_pc.history = ["Turned into a Succubus.", "Converted his friend into a minion."]
		_pc.sprite_index = spr_succubus_large;
		_pc.image_xscale = 0.4;
		_pc.image_yscale = 0.4;
		
		// Create the friend
		var _friend = instance_create_layer(0, 0, people_layer.entities, obj_minion);
		_friend.name = _new_names[1] ;
		_friend.guest_name = scr_get_client_name();
		_friend.is_friend = true;
		_friend.tags = ["devoted"];
		_friend.backstory = "Your best friend.";
		_friend.history = ["Returned to see what had happened.", "Slept with a succubus and was converted into a minion."]
		_friend.sprite_index = spr_devoted_large;
		_friend.image_xscale = 0.4;
		_friend.image_yscale = 0.4;
		
		// Put the player in the boudoir. There is only one.
		var _first = obj_mansion_manager.first_room;
		scr_move_minion(_pc, _first);
		
		// Put the friend in the adjacent room. Currently guaranteed by layout.
		// Later in development the player will get to make the choice of locations.
		var _second = ds_grid_get(global.mansion_map, _first.grid_x + 1, _first.grid_y);
		if (_second != -1) {
			scr_move_minion(_friend, _second);
		}
		else {
			show_debug_message("Couldn't find room for second minion.");
			show_debug_message("Check Ground templates to fix.");
			return [_pc];
		}
		
		return [_pc, _friend];
	}

}
