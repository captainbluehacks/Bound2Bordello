if (show_display_specs) {
    var gui_w = display_get_gui_width();
    var gui_h = display_get_gui_height();
    
	var _box_h = 600;
	var _box_w = 1000;
	
	var _scale = 1;

	var _tw = _box_w * _scale; // rough width
	var _th = _box_h * _scale; // rough height

	var _cx = gui_w / 2 - _tw / 2;
	var _cy = gui_h / 2 - _th / 2;

	// Background
	draw_set_alpha(0.7);
	draw_set_colour(c_black);
	draw_rectangle(_cx - 10, _cy - 10, _cx + _tw + 10, _cy + _th + 10, false);
	draw_set_alpha(1.0);

	// Text (pass window-space coords that land at _cx, _cy after scaling)
	display_write_all_specs(gui_w / 2, gui_h / 2, _scale);
}