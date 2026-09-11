
	/// @description Get all unique neighbouring chamber instances (excluding self).
	/// @param {instance} _chamber
	/// @return {array} Unique adjacent obj_chamber instances.
	function scr_get_adjacent_chambers(_chamber) {
	    var _result = []; 
    
	    var _size = global.size_dims[_chamber.chamber_size];
	    var _gx = _chamber.grid_x;
	    var _gy = _chamber.grid_y;
	    var _gw = _size.w;
	    var _gh = _size.h;
    
	    for (var _x = _gx - 1; _x <= _gx + _gw; _x++) {
	        for (var _y = _gy - 1; _y <= _gy + _gh; _y++) {
	            // Skip cells that are part of this chamber itself
	            if (_x >= _gx && _x < _gx + _gw && _y >= _gy && _y < _gy + _gh) continue;
            
	            // Bounds check
	            if (_x < 0 || _x >= ds_grid_width(global.mansion_map)) continue;
	            if (_y < 0 || _y >= ds_grid_height(global.mansion_map)) continue;
            
	            var _inst = ds_grid_get(global.mansion_map, _x, _y);
            
	            // Valid instance check (and not self)
	            if (_inst != -1 && instance_exists(_inst) && _inst != _chamber) {
	                array_push(_result, _inst);
	            }
	        }
	    }
    
	    // Remove duplicates in one go
	    return array_unique(_result);
	}

	/// @description Check if any adjacent chamber matches a room type (optionally in a direction).
	function scr_check_adjacent(_chamber, _cond) {
	    var _adj = scr_get_adjacent_chambers(_chamber); // This now returns an array []
    
	    for (var _i = 0; _i < array_length(_adj); _i++) {
	        var _neighbour = _adj[_i]; // Simple array indexing
        
	        // If a specific direction is required, verify it
	        if (map_exists(_cond, "direction")) {
	            if (!scr_is_in_direction(_chamber, _neighbour, _cond.direction)) continue;
	        }
        
	        // Wildcard or type match
	        if (_cond.room_type == "*" || _neighbour.chamber_type == _cond.room_type) {
	            return true; // No need to destroy anything!
	        }
	    }
    
	    return false; // No need to destroy anything!
	}


	/// @description Check whether a neighbour touches the subject on a given side.
	/// Strict adjacency only: the neighbour must share an edge with the subject's
	/// bounding box (no diagonals). Multi-cell rooms are compared by their full
	/// bounding boxes, not just top-left corners.
	/// @param {instance} _subject   The chamber being evaluated.
	/// @param {instance} _neighbour A neighbouring chamber instance.
	/// @param {string} _direction   "up", "down", "left" or "right".
	/// @return {bool} True if the neighbour is strictly in that direction of the subject.
	function scr_is_in_direction(_subject, _neighbour, _direction) {
	    var _s = global.size_dims[_subject.chamber_size];
	    var _n = global.size_dims[_neighbour.chamber_size];

	    // Subject bounding box (top-left + size)
	    var _sx1 = _subject.grid_x;
	    var _sy1 = _subject.grid_y;
	    var _sx2 = _sx1 + _s.w - 1;   // inclusive right edge
	    var _sy2 = _sy1 + _s.h - 1;   // inclusive bottom edge

	    // Neighbour bounding box (top-left + size)
	    var _nx1 = _neighbour.grid_x;
	    var _ny1 = _neighbour.grid_y;
	    var _nx2 = _nx1 + _n.w - 1;
	    var _ny2 = _ny1 + _n.h - 1;

	    switch (_direction) {
	        case "up":     // neighbour's bottom edge touches subject's top edge, with horizontal overlap
	            return (_ny2 == _sy1) && (_nx1 <= _sx2) && (_nx2 >= _sx1);
	        case "down":   // neighbour's top edge touches subject's bottom edge, with horizontal overlap
	            return (_ny1 == _sy2 + 1) && (_nx1 <= _sx2) && (_nx2 >= _sx1);
	        case "left":   // neighbour's right edge touches subject's left edge, with vertical overlap
	            return (_nx2 == _sx1 - 1) && (_ny1 <= _sy2) && (_ny2 >= _sy1);
	        case "right":  // neighbour's left edge touches subject's right edge, with vertical overlap
	            return (_nx1 == _sx2 + 1) && (_ny1 <= _sy2) && (_ny2 >= _sy1);
	        default:
	            show_debug_message("Unknown adjacency direction: " + string(_direction));
	            return false;
	    }
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
	    if (_chamber.upgrade_id != noone && _chamber.upgrade_id != "") {
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
	    var _floor_rows = scr_grid_y_to_floor(_chamber.grid_y);
		
		if (_floor_rows == noone) {
			show_debug_message("Couldn't get valid floor from: " + string(_chamber.grid_y));
			
			// No clean way to recover, so let's just return 0 for none.
			return (0);	
		}
    
	    for (var _y = _floor_rows[0]; _y <= _floor_rows[1]; _y++) {
	        for (var _x = 0; _x < ds_grid_width(global.mansion_map); _x++) {
	            var _inst = ds_grid_get(global.mansion_map, _x, _y);
	            if (_inst == -1 || !instance_exists(_inst)) continue;
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
	function scr_grid_y_to_floor(_y) {
	    // Adjust these ranges to match your actual grid layout:
	    // e.g. basement = rows 6-7, ground = rows 4-5, first = rows 2-3, attic = rows 0-1

		if (_y == 6 or _y==7) return [6,7];
		if (_y == 5 or _y==4) return [4,5];
		if (_y == 3 or _y==2) return [2,3];
		if (_y == 1 or _y==0) return [0,1];
	
		return noone;
	
	}

