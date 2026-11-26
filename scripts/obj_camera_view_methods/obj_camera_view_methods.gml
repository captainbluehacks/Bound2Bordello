/// @description Builds and returns the camera's view-method struct (set_target, target_is_valid, snap_to_target, init_view). No params.
/// @return {map} Struct of view-control closures bound to this camera instance.
function __obj_camera_view_methods(){

	/// @description Sets current_target and resets scroll_offset to zero. No return.
	/// @param {instance|map} _target Instance or struct with x/y to track.
	set_target = function(_target) {
		current_target = _target;
		scroll_offset = {x: 0, y: 0};
	}

	/// @description Returns true if current_target is a live instance or a plain struct (x/y point). No params.
	/// @return {bool} Whether the current target can be followed.
	target_is_valid = function(){
		return (!is_struct(current_target) && instance_exists(current_target) || is_struct(current_target)) ;
	}

	/// @description Instantly clamps and moves the view so the target is centred, clearing scroll_offset. Exits early if the target is invalid. No return.
	snap_to_target = function(){
		if(!target_is_valid()) exit;
	
		scroll_offset = {x: 0, y: 0};
	
		var _tar_x = current_target.x - VIEW_W / 2 ;
		var _tar_y = current_target.y - VIEW_H / 2 ;
	
		_tar_x = clamp(_tar_x, 0, room_width - VIEW_W);
		_tar_y = clamp(_tar_y, 0, room_height - VIEW_H);

		camera_set_view_pos(VIEW, _tar_x, _tar_y);
	};

	/// @description Enables the view port at BASE_W x BASE_H with a 1366x768 window port and clears the camera target. No params, no return.
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