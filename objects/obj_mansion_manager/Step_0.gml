selected_obj = obj_selection_manager.get_selection();

if (selected_obj == noone && !instance_exists(selected_obj)) {
	// Deselected - hide the sprite.
	layer_sprite_alpha(room_highlight, 0);
}
else if (selected_obj.object_index == obj_chamber) {
	
	// Move the sprite to our rooms x,y coords
	layer_sprite_x(room_highlight, selected_obj.x);
	layer_sprite_y(room_highlight, selected_obj.y);
		
	// Scale the sprite to fit the room.
	layer_sprite_xscale(room_highlight, selected_obj.sprite_width / sprite_get_width(spr_selected_chamber));
	layer_sprite_yscale(room_highlight, selected_obj.sprite_height / sprite_get_height(spr_selected_chamber));
		
	// Smooth pulse using the animation frame (0..5)
	var _t = layer_sprite_get_index(room_highlight) / 5.0;
	layer_sprite_alpha(room_highlight, 0.25 + 0.2 * sin(_t * 6.28));	
};
