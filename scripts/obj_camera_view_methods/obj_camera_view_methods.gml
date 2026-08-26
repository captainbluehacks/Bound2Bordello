function __obj_camera_view_methods(){

	set_target = function(_target) {
		current_target = _target;
		scroll_offset = {x: 0, y: 0};
	}

	target_is_valid = function(){
		return (!is_struct(current_target) && instance_exists(current_target) || is_struct(current_target)) ;
	}

	snap_to_target = function(){
		if(!target_is_valid()) exit;
	
		scroll_offset = {x: 0, y: 0};
	
		var _tar_x = current_target.x - VIEW_W / 2 ;
		var _tar_y = current_target.y - VIEW_H / 2 ;
	
		_tar_x = clamp(_tar_x, 0, room_width - VIEW_W);
		_tar_y = clamp(_tar_y, 0, room_height - VIEW_H);

		camera_set_view_pos(VIEW, _tar_x, _tar_y);
	};

	init_view = function(){
		view_enabled = true; 
		view_visible[0] = true;
		camera_set_view_size(VIEW, BASE_W, BASE_H);

		// Safety 
		camera_set_view_target(VIEW, noone);

		view_set_wport(0, 1366);
		view_set_hport(0, 768);
		view_set_xport(0,0);
		view_set_yport(0,0);
	};

}