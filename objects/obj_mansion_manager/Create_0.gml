// All data intialisation is now done in _obj_mansion_init
// This allows for clear separation during testing.
if (!instance_exists(obj_mansion_init)) {
	show_debug_message("No mansion init found");
}

// Create a grid for tracking chambers.
var _grid_width = 10;
var _grid_height = 8;
	
// Shared grid tracking which chamber instance occupies each cell.
// Global because it is read by many objects (chambers, minions) via the
// query functions below, not just obj_mansion_manager.
global.mansion_map = ds_grid_create(_grid_width, _grid_height);
		
// Set everything to unassigned.
ds_grid_set_region(global.mansion_map, 0, 0, _grid_width -1, _grid_height - 1, -1);

// Setup layers
mansion_layer = {
chamber : layer_create(layer_type.chambers), 
props : layer_create(layer_type.props),
shell : layer_create(layer_type.shell)
}

first_room = noone;


// Make sure all chamber sprites are available.
gml_pragma("MarkTagAsUsed", "chamber");

var _blueprints = define_floors();

add_room_instances(_blueprints);

room_highlight = layer_sprite_create(mansion_layer.props, 0,0, spr_selected_chamber);
layer_sprite_alpha(room_highlight, 0);

selected_obj = noone;
