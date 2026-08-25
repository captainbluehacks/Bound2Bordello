selected = obj_selection_manager.get_selection();

if (selected != noone && selected.object_index == obj_chamber) {
	with (selected) {
		draw_sprite_stretched_ext(spr_selected_chamber, 0, x, y, sprite_width, sprite_height, c_white, 0.4)
	}
};