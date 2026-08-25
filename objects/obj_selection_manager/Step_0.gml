if (mouse_check_button_pressed(mb_left)) {
    // Find the first instance of obj_chamber at the mouse position
    hovered = instance_position(mouse_x, mouse_y, obj_selectable);

    if (hovered != noone) {
        selected = hovered;
		obj_camera.set_target(selected);
    } else {
        selected = noone; // Deselect if clicking empty space
    }
}