if (!instance_exists(obj_selection_manager)) {
	show_debug_message("Selection manager does not exist.");
	exit;
}

selected_object = obj_selection_manager.get_selection();

if (selected_object == noone && !instance_exists(selected_object)) {
	// Deselected - hide the panel.
	active_tab = SELECT_TAB.NONE;
}
else if (selected_object.object_index == obj_chamber) {
	if (array_contains(obstacles, selected_object.chamber_type)) {
		active_tab = SELECT_TAB.OBSTACLE;
	}
	else {	
		active_tab = SELECT_TAB.ROOM;
	}
}
else if (selected_object.object_index == obj_minion) {
	active_tab = SELECT_TAB.MINIONS;
}