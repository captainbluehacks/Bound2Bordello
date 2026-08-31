// Initialise our script
__obj_mansion_chamber_type_methods() ;
__obj_mansion_room_methods();

// Load chamber types
scr_load_chamber_types();

// Setup Room Constants	    
setup_constants();

// Setup layers
mansion_layer = {
chamber : layer_create(layer_type.chambers), 
props : layer_create(layer_type.props),
shell : layer_create(layer_type.shell)
}

var _blueprints = define_floors();

add_room_instances(_blueprints);

room_highlight = layer_sprite_create(mansion_layer.props, 0,0, spr_selected_chamber);
layer_sprite_alpha(room_highlight, 0);
