var _sprite = "spr_chamber_" + chamber_type + "_" + global.size_dims[chamber_size].name ;

sprite_index = asset_get_index(_sprite);
image_index = irandom(sprite_get_number(sprite_index) -1);

// Cache the tag list for fast access
var _tags = obj_mansion_manager.scr_get_chamber_tags(chamber_type);
my_tags = [];
for (var i = 0; i < ds_list_size(_tags); i++) {
    array_push(my_tags, ds_list_find_value(_tags, i));
}


// Runtime state
minion = noone;          // assigned minion instance (or no)
client = [];	
upgrade_id = noone;        // list of upgrade IDs installed this cycle
is_reclaiming = false;