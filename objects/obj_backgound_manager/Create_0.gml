bg_layer = layer_create(layer_type.bg);
bg_props_layer = layer_create(layer_type.bg_props);



fixed = {
	underground : 3 * floor(random(sprite_get_number(spr_background_underground) / 3)),
	sky : 6 * floor(random(sprite_get_number(spr_sky_day) / 6))
} ;