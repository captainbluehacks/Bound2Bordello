selected = obj_selection_manager.get_selection();
if (selected = noone) {
	// Deselected - hide the sprite.
	layer_sprite_alpha(room_highlight, 0);
}
else if (selected.object_index == obj_chamber) {
	
	// Move the sprite to our rooms x,y coords
	layer_sprite_x(room_highlight, selected.x);
	layer_sprite_y(room_highlight, selected.y);
		
	// Scale the sprite to fit the room.
	layer_sprite_xscale(room_highlight, selected.sprite_width / sprite_get_width(spr_selected_chamber));
	layer_sprite_yscale(room_highlight, selected.sprite_height / sprite_get_height(spr_selected_chamber));
		
	// TODO: Have this pulse by varying the alpha.
	layer_sprite_alpha(room_highlight, 0.4);	
};