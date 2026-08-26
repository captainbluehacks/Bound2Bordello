var _sel = obj_selection_manager.get_selection();


if (_sel = noone && !instance_exists(_sel)) {
	// Deselected - hide the sprite.
	layer_sprite_alpha(room_highlight, 0);
}
else if (_sel.object_index == obj_chamber) {
	
	// Move the sprite to our rooms x,y coords
	layer_sprite_x(room_highlight, _sel.x);
	layer_sprite_y(room_highlight, _sel.y);
		
	// Scale the sprite to fit the room.
	layer_sprite_xscale(room_highlight, _sel.sprite_width / sprite_get_width(spr_selected_chamber));
	layer_sprite_yscale(room_highlight, _sel.sprite_height / sprite_get_height(spr_selected_chamber));
		
	// Smooth pulse using the animation frame (0..5)
	var _t = layer_sprite_get_image_index(room_highlight) / 5.0;
	layer_sprite_alpha(room_highlight, 0.25 + 0.2 * sin(_t * TAU));	
};
