enum FLOOR {
	BASEMENT,
	GROUND,
	FIRST,
	ATTIC,
	LENGTH
}

enum ROOM_SIZE {
    SMALL,   // 1x1
    MEDIUM,  // 2x1
    LARGE    // 2x2
}; 

// Define the room sizes
global.size_dims = [
	{ w : 1, h : 1, name : "small"},
	{ w : 2, h : 1, name : "medium"},
	{ w : 2, h : 2, name : "large"}
	] ;

function __obj_mansion_room_methods(){
	
	setup_constants = function() {
		
		// Make sure all chamber sprites are available.
		gml_pragma("MarkTagAsUsed", "chamber");
		
		// Create a grid for tracking chambers.
		var _grid_width = 10;
		var _grid_height = 8;
		mansion_map = ds_grid_create(_grid_width, _grid_height);
		
		// Set everything to unassigned.
		ds_grid_set_region(mansion_map, 0, 0, _grid_width -1, _grid_height - 1, -1);
	}
	

	define_floors = function() {
		
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
	
	
	validate_template = function(_template) {
		// For now lets just return true.
		return (true);	
	}
	
	add_room_instances = function(_blueprints) {
		
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
			
			show_debug_message(string(_data.grid_x)+ ", " + string(_data.grid_y) + " - " + string(_px)+ ", " + string(_py))
			
			// Set variables before create, as then we can pick a sprite before creation.
			var _inst = instance_create_layer(_px, _py, global.mansion_layer.chamber, obj_chamber, 
				{ chamber_type : _data.type, chamber_size : _data.size } );
			
			// Now populate our DS Grid
			for (var xx = 0; xx < global.size_dims[_data.size].w; xx++) {
				for (var yy = 0; yy < global.size_dims[_data.size].h; yy++) {
					
					// Store the instance ID in the grid for fast lookup later
					ds_grid_set(mansion_map, _data.grid_x + xx, _data.grid_y + yy, _inst);
				}
			}
		}
	}
}