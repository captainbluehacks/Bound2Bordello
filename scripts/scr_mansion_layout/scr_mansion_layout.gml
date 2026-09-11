

function define_floors() {
		
	var _schema_file = [
		"basement.json", 
		"ground.json", 
		"first.json", 
		"attic.json"
	] ;	
		
	var _blueprints = [];
		
	for (var i=0; i < array_length(_schema_file); i++) {
			
		var _buffer = buffer_load(_schema_file[i]);
		var _json_string = buffer_read(_buffer, buffer_string);
		buffer_delete(_buffer);
			
		var _floor_blueprints =  json_parse(_json_string);
		var _template = _floor_blueprints[0];
			
		repeat(10) {
			// Pick a random template
			var _chosen = irandom(array_length(_floor_blueprints) - 1);
			_template = _floor_blueprints[_chosen];
				
			if (validate_template(_template)) {
				break;
			} else {
				show_debug_message("Invalid Blueprint Found in " + _schema_file[i] + " Index: " + _chosen);
			}
		}
			
		_blueprints = array_concat(_blueprints, _template.layout) ;	
	}
		
	return (_blueprints);
}
	
	
function validate_template(_template) {
	// For now lets just return true.
	return (true);	
}
	
function add_room_instances(_blueprints) {
		
	if (!variable_global_exists("mansion_map")) {
		show_debug_message("Mansion map didn't exist when we got here.")
	}
		
	// Define constants
	var _cell_size = 320;
		
	// Our room has space for background before the grid actually starts.
	var _offset_x = 960; 
	var _offset_y = 320;	
		
	// Iterate through our room list and create instances for each.
	for (var chamber = 0; chamber < array_length(_blueprints); chamber++) {
		var _data = _blueprints[chamber];
			
		var _px = _data.grid_x * _cell_size + _offset_x;
		var _py = _data.grid_y * _cell_size + _offset_y;
			
		// Set variables before create, as then we can pick a sprite before creation.
		var _inst = instance_create_layer(_px, _py, mansion_layer.chamber, obj_chamber, 
			{ 
				chamber_type : _data.type, 
				chamber_size : _data.size, 
				grid_x       : _data.grid_x,
				grid_y       : _data.grid_y
				} );
			
		// Now populate our DS Grid
		for (var xx = 0; xx < global.size_dims[_data.size].w; xx++) {
			for (var yy = 0; yy < global.size_dims[_data.size].h; yy++) {
					
				// Store the instance ID in the grid for fast lookup later
				ds_grid_set(global.mansion_map, _data.grid_x + xx, _data.grid_y + yy, _inst);
			}
		}
	}
}

