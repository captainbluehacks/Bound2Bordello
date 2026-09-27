var _sprite = "spr_chamber_" + chamber_type + "_" + global.size_dims[chamber_size].name ;

sprite_index = asset_get_index(_sprite);
image_index = 0;

if (sprite_index == -1) {
	// Handle sprite not found
	show_debug_message(_sprite + " not found.");
	
	sprite_index = asset_get_index("spr_chamber_not_found_" + global.size_dims[chamber_size].name);
}
else {
	image_index = irandom(sprite_get_number(sprite_index) -1);
}

// Cache the tag list for fast access
var _tags = scr_get_chamber_tags(chamber_type);
my_tags = [];
for (var i = 0; i < ds_list_size(_tags); i++) {
    array_push(my_tags, ds_list_find_value(_tags, i));
}

ds_list_destroy(_tags);

// Runtime state
chamber_id = gen_unique_id(COUNTER.CHAMBER);
max_minions = 1;
minions = [];			// List of Minions
max_clients = 1;
clients = [];			// List of Clients

upgrade_id = noone;		// list of upgrade IDs installed this cycle
is_reclaiming = false;


/// @description Get coordinate of where to place the person in the room.
/// @param_pool _person The person to get the coordinate of.
/// @param_pool _coord  The x or y coordinate requested.
/// @return The required coordinate within the room.
function get_person_position(_person, _coord) {
	// Person or coord out of boounds
	if (_person == noone || _coord == noone || 
		_person.object_index != obj_person ||
		!array_contains(["y", "Y", "x", "X"], _coord)) {
			show_debug_message("Person or coordinate out of bounds when trying to get_minion_position");
			show_debug_message("Person: " + string(_person) + " coordinate requested: " + string(_coord));
			return -1 
	};
	
	// Get all the people
	var _people = array_concat(minions, clients);
	
	
	// Person not in room
	if (!array_contains(_people, _person)) {
			show_debug_message("Person not in room when trying to get_minion_position.");
			show_debug_message("Person: " + string(_person));
			return -1
	};
	
	if (_coord == "y" || _coord == "Y") {
		// Room y + pad value.
		return (y+15) ;
	}
	
	// For now we're just going to distribute people evenly through the rooms.
	var _chamber_pixels = sprite_get_width(sprite_index);
	var _total_people = array_length(_people);
	var _pad = floor(_chamber_pixels / _total_people);
	

	
	var _idx = array_get_index(minions, _person);
		
	if (_idx = -1) {
		// Something went wrong. Log it and stick baby in the corner.
		show_debug_message("Minion wasn't in room despite earlier check.");
		show_debug_message("Minion: " + string(_person));
		return 0;
	}
	else {
		// Add one for the first padding.
		return (_idx + 1) * _pad ;
	}

}