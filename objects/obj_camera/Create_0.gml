/// @description
__obj_camera_view_methods()
__obj_camera_window_methods()


window_scale = calculate_max_window_scale();
init_window();

// Camera Controls
current_target = {x: 300, y: 1460} ;
scroll_speed = 0.15;
scroll_offset = {x: 0, y: 0};

// Zoom
zoom = {
	width: BASE_W,
	height: BASE_H,
	spd: .1,
	inc: 100,
	min_width: BASE_W / 4,
	max_width: BASE_W * 3,
	set: function(_width) {
		width = clamp(_width, min_width, max_width);
		height = width / BASE_ASPECT ;
	},
	change: function() {
		var _zoom = mouse_wheel_down() - mouse_wheel_up();
		set(width + _zoom * inc);
	},
	apply: function() {
		var _center_x = VIEW_CENTER_X;
		var _center_y = VIEW_CENTER_Y;
		camera_set_view_size(VIEW, lerp(VIEW_W, width, spd), lerp(VIEW_H, height, spd));
		camera_set_view_pos(VIEW, _center_x - VIEW_W / 2, _center_y - VIEW_H / 2);
	}
}