/// @description
zoom.change();

if (keyboard_check_pressed(vk_f4)) {
	window_set_fullscreen(!WIN_GET_FULL);
	show_debug_message("F4 pressed");
	
	var _scale = WIN_GET_FULL ? calculate_max_window_scale(true) : window_scale;
	surface_resize(APP_SURF, BASE_W * _scale, BASE_H * _scale);
}

if (keyboard_check_pressed(vk_f3)) {
	if (WIN_GET_FULL) exit;
	
	var _new_scale = (window_scale + 1) mod (calculate_max_window_scale() + 1);
	window_scale = max(_new_scale, 1);
	window_set_size(BASE_W * window_scale, BASE_H * window_scale);
	window_center();
	surface_resize(APP_SURF, BASE_W * window_scale, BASE_H * window_scale);
}