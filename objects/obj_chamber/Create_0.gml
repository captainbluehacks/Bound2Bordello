var _sprite = "spr_chamber_" + chamber_type + "_" + global.size_dims[chamber_size].name ;

sprite_index = asset_get_index(_sprite);
image_index = irandom(sprite_get_number(sprite_index) -1);