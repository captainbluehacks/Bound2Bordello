/// @description Builds and returns the camera's window-method struct (calculate_max_window_scale, init_window, follow_target, camera_set_view_pos_clamped). No params.
/// @return {map} Struct of window-control closures bound to this camera instance.
function __obj_camera_window_methods(){
	/// @description Returns the largest whole-number integer scale that fits DISP_W x DISP_H within BASE_W x BASE_H (capped at 1).
	/// Unless _full_screen, a whole-number height scale is decremented by one so the window stays inside the display.
	/// @param {bool} [_full_screen] Allow an exact-fit whole-number scale; defaults to false.
	/// @return {real} Maximum integer window scale (at least 0).
	calculate_max_window_scale = function(_full_screen = false){
		var _max_h_scale = DISP_H / BASE_H ;
		var _max_v_scale = DISP_W / BASE_W ;

		if (!_full_screen && frac(_max_h_scale) == 0) {
			_max_h_scale--;
		}
		_max_h_scale = min(_max_h_scale, 1);

		return(floor(min(_max_h_scale, _max_v_scale)));
	}
	
	/// @description Resizes and centres the OS window at BASE_W/BASE_H x window_scale, resizes APP_SURF to BASE_W x BASE_H and sets the GUI size. No params, no return.
	init_window = function(){
		window_set_size(BASE_W * window_scale, BASE_H * window_scale);
		window_center();

		surface_resize(APP_SURF, BASE_W, BASE_H);
		//surface_resize(application_surface, BASE_W * window_scale, BASE_H * window_scale);

		display_set_gui_size(BASE_W, BASE_H);
	}
	
	/// @description Smoothly scrolls the view toward current_target's focus point (lerped by scroll_speed, offset by scroll_offset) and clamps it to the room. Exits early if the target is invalid. No return.
	follow_target = function(){
		if(!target_is_valid()) exit;

		var _focus = get_focus();
		var _tar_x = _focus.x + scroll_offset.x - VIEW_W / 2;
		var _tar_y = _focus.y + scroll_offset.y - VIEW_H / 2;

		// Smooth Scroll
		_tar_x = lerp(VIEW_X, _tar_x, scroll_speed);
		_tar_y = lerp(VIEW_Y, _tar_y, scroll_speed);

		_tar_x = clamp(_tar_x, 0, room_width - VIEW_W);
		_tar_y = clamp(_tar_y, 0, room_height - VIEW_H);

		// Move camera position.
		camera_set_view_pos(VIEW, _tar_x, _tar_y);
	}
	
	/// @description Moves the view to (_tar_x, _tar_y) clamped to the room; if the view is larger than the room on an axis it centres that axis instead. No return.
	/// @param {real} _tar_x Desired view x position.
	/// @param {real} _tar_y Desired view y position.
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