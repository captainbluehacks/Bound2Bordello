// Setup Functions
__obj_people_manager_helpers();

// Define Layers
// Setup layers
mansion_layer = {
entities : layer_create(layer_type.entities)
}

// Define core datastructures

name_pool = scr_load_json_file("names.json");

client_pool = scr_get_new_clients("village");
minion_pool = [];
player_ref = noone;

