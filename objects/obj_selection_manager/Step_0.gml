// First check if the UI is doing something.
if (!global.ui_blocked) {

	// Find the first selectable object at the mouse position
	hovered = instance_position(mouse_x, mouse_y, obj_selectable);

	if (mouse_check_button_pressed(mb_left)) {
	    if (hovered != noone) {
		    selected = hovered;
		
			// Refocus to ensure the room is centered.
			obj_camera.set_target(selected);
	    } else {
		    selected = noone; // Deselect if clicking empty space
		}
	}
}

// Click right mouse button to deselect.
if (mouse_check_button_pressed(mb_right)) {
	selected = noone;
}