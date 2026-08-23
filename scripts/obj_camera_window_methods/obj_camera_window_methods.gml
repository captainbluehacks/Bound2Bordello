function __obj_camera_window_methods(){
	calculate_max_window_scale = function(_full_screen = false){
		var _max_h_scale = DISP_H / BASE_H ;
		var _max_v_scale = DISP_W / BASE_W ;

		if (!_full_screen && frac(_max_h_scale) == 0) {
			_max_h_scale--;
		}
		_max_h_scale = min(_max_h_scale, 1);

		return(floor(min(_max_h_scale, _max_v_scale)));
	}
	
	init_window = function(){
		window_set_size(BASE_W * window_scale, BASE_H * window_scale);
		window_center();

		surface_resize(APP_SURF, BASE_W, BASE_H);
		//surface_resize(application_surface, BASE_W * window_scale, BASE_H * window_scale);

		display_set_gui_size(BASE_W, BASE_H);
	}
	
	follow_target = function(){
		if(!target_is_valid()) exit;

		var _tar_x = current_target.x - VIEW_W / 2;
		var _tar_y = current_target.y - VIEW_H / 2;

		// Smooth Scroll
		_tar_x = lerp(VIEW_X, _tar_x, scroll_speed);
		_tar_y = lerp(VIEW_Y, _tar_y, scroll_speed);

		_tar_x = clamp(_tar_x, 0, room_width - VIEW_W);
		_tar_y = clamp(_tar_y, 0, room_width - VIEW_H);

		// Move camera position.
		camera_set_view_pos(VIEW, _tar_x, _tar_y);
	}
	
	camera_set_view_pos_clamped = function(_tar_x, _tar_y){
		_tar_x = clamp(_tar_x, 0, room_width - VIEW_W);
		_tar_y = clamp(_tar_y, 0, room_height - VIEW_H);

		if(VIEW_W > room_width)
			_tar_x = room_width / 2 - VIEW_W / 2 ;
			
		if (VIEW_H > room_height)
			_tar_y = room_height / 2 - VIEW_H / 2 ;
		// Move camera position.
		camera_set_view_pos(VIEW, _tar_x, _tar_y);
	}
}