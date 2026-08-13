// Initialise our script
__obj_mansion_room_methods();
setup_constants();

// Setup layers
mansion_layer = {
chamber : layer_create(layer_type.chambers), 
props : layer_create(layer_type.props),
shell : layer_create(layer_type.shell)
}

var _blueprints = define_floors();

add_room_instances(_blueprints);
