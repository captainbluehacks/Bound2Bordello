// Setup Functions
__obj_people_manager_helpers();

// Define Layers
// Setup layers
people_layer = {
entities : layer_create(layer_type.entities), 
clothes  : layer_create(layer_type.clothes)
}

// Ensure Sprites are available
gml_pragma("MarkTagAsUsed", "minion");


// Define core datastructures
name_pool = scr_load_json_file("names.json");

active_clients = scr_get_new_clients("village");
active_minions = scr_create_first_minions();
player_ref = active_minions[0];
