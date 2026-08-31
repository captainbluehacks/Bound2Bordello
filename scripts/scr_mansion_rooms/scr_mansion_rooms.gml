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

// Shared grid tracking which chamber instance occupies each cell.
// Global because it is read by many objects (chambers, minions) via the
// query functions below, not just obj_mansion_manager.
global.mansion_map = noone;

function __obj_mansion_room_methods(){
	
	setup_constants = function() {
		
		// Make sure all chamber sprites are available.
		gml_pragma("MarkTagAsUsed", "chamber");
		
		// Create a grid for tracking chambers.
		var _grid_width = 10;
		var _grid_height = 8;
		global.mansion_map = ds_grid_create(_grid_width, _grid_height);
		
		// Set everything to unassigned.
		ds_grid_set_region(global.mansion_map, 0, 0, _grid_width -1, _grid_height - 1, -1);
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
}

/// @description Get all unique neighbouring chamber instances (excluding self).
/// Checks the 4-directional neighbours of every cell this room occupies.
/// @param {instance} _chamber
/// @return {ds_list} Unique adjacent obj_chamber instances.
function scr_get_adjacent_chambers(_chamber) {
    var _result = ds_list_create();
    var _seen = ds_set_create();
    
    // Get this chamber's bounding box on the grid
    var _size = global.size_dims[_chamber.chamber_size];
    var _gx = _chamber.grid_x;
    var _gy = _chamber.grid_y;
    var _gw = _size.w;
    var _gh = _size.h;
    
    // Check all cells in a 1-cell ring around the bounding box
    for (var _x = _gx - 1; _x <= _gx + _gw; _x++) {
        for (var _y = _gy - 1; _y <= _gy + _gh; _y++) {
            // Skip cells that are part of this chamber itself
            if (_x >= _gx && _x < _gx + _gw && _y >= _gy && _y < _gy + _gh) continue;
            
            // Bounds check
            if (_x < 0 || _x >= ds_grid_width(global.mansion_map)) continue;
            if (_y < 0 || _y >= ds_grid_height(global.mansion_map)) continue;
            
            var _inst = ds_grid_get(global.mansion_map, _x, _y);
            if (_inst == -1 || !is_instance(_inst)) continue;
            if (_inst == _chamber) continue;
            
            // Deduplicate (multi-cell neighbours will appear multiple times)
            if (ds_set_find(_seen, _inst) != -1) continue;
            ds_set_add(_seen, _inst);
            ds_list_add(_result, _inst);
        }
    }
    
    ds_set_destroy(_seen);
    return _result;
}


/// @description Check if any adjacent chamber matches a room type (optionally in a direction).
function scr_check_adjacent(_chamber, _cond) {
    var _adj = scr_get_adjacent_chambers(_chamber);
    
    for (var _i = 0; _i < ds_list_size(_adj); _i++) {
        var _neighbour = ds_list_find_value(_adj, _i);
        
        // If a specific direction is required, verify it
        if (map_exists(_cond, "direction")) {
            if (!scr_is_in_direction(_chamber, _neighbour, _cond.direction)) continue;
        }
        
        // Wildcard or type match
        if (_cond.room_type == "*" || _neighbour.chamber_type == _cond.room_type) {
            ds_list_destroy(_adj);
            return true;
        }
    }
    
    ds_list_destroy(_adj);
    return false;
}

/// @description Get all effective tags for a chamber (type tags + upgrade tags).
function scr_get_effective_tags(_chamber) {
    var _tags = [];
    
    // Base type tags
    var _base_tags = scr_get_chamber_tags(_chamber.chamber_type);
    for (var i = 0; i < ds_list_size(_base_tags); i++) {
        array_push(_tags, ds_list_find_value(_base_tags, i));
    }
    ds_list_destroy(_base_tags);
    
    // Upgrade tags
    if (_chamber.upgrade_id != no && _chamber.upgrade_id != "") {
        var _upg = scr_get_upgrade(_chamber.upgrade_id);
        if (_upg != undefined && map_exists(_upg, "tags_added")) {
            for (var i = 0; i < array_length(_upg.tags_added); i++) {
                // Avoid duplicates
                var _found = false;
                for (var j = 0; j < array_length(_tags); j++) {
                    if (_tags[j] == _upg.tags_added[i]) { _found = true; break; }
                }
                if (!_found) array_push(_tags, _upg.tags_added[i]);
            }
        }
    }
    
    return _tags;  // plain array of strings
}


/// @description Count unique chambers on the same floor as _chamber that carry a given tag.
function scr_count_tag_on_floor(_chamber, _tag, _max) {
    var _count = 0;
    var _seen = ds_set_create();
    
    // Determine which row(s) of the grid correspond to this chamber's floor
    // (Your FLOOR enum maps to grid_y ranges — adjust to your layout)
    var _floor_rows = scr_get_floor_row_range(_chamber.floor);
    
    for (var _y = _floor_rows[0]; _y <= _floor_rows[1]; _y++) {
        for (var _x = 0; _x < ds_grid_width(global.mansion_map); _x++) {
            var _inst = ds_grid_get(global.mansion_map, _x, _y);
            if (_inst == -1 || !is_instance(_inst)) continue;
            if (ds_set_find(_seen, _inst) != -1) continue;
            ds_set_add(_seen, _inst);
            
            // Check if this chamber or any of it's upgrades has the tag
            var _eff_tags = scr_get_effective_tags(_inst);
			for (var t = 0; t < array_length(_eff_tags); t++) {
				if (_eff_tags[t] == _tag) { _count++; break; }
			}

        }
    }
    
    ds_set_destroy(_seen);
    return min(_count, _max);
}


/// @description Given a rooms Y coord, return the pair of y coords that are on the same floor.
function scr_get_floor_row_range(_y) {
    // Adjust these ranges to match your actual grid layout:
    // e.g. basement = rows 6-7, ground = rows 4-5, first = rows 2-3, attic = rows 0-1
    
	if (_y == 6 or _y==7) return [6,7];
	if (_y == 5 or _y==4) return [5,4];
	if (_y == 3 or _y==2) return [3,2];
	if (_y == 1 or _y==0) return [0,1];
	
	return noone;
	
}
