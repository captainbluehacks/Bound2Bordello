/// @description Builds and returns the camera's view-method struct (set_target, target_is_valid, get_focus, snap_to_target, init_view). No params.
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

	/// @description Returns the {x,y} point the view should centre on for current_target. Uses the target's get_focus_point() when it has one (e.g. any obj_selectable), otherwise falls back to its x/y. No params.
	/// @return {map} Struct with x/y of the focus point.
	get_focus = function(){
		if (current_target.get_focus_point != undefined) return current_target.get_focus_point();
		return {x: current_target.x, y: current_target.y};
	}

	/// @description Instantly clamps and moves the view so the target's focus point is centred, clearing scroll_offset. Exits early if the target is invalid. No return.
	snap_to_target = function(){
		if(!target_is_valid()) exit;
	
		scroll_offset = {x: 0, y: 0};
	
		var _focus = get_focus();
		var _tar_x = _focus.x - VIEW_W / 2 ;
		var _tar_y = _focus.y - VIEW_H / 2 ;

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