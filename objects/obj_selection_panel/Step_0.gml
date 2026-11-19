if (!instance_exists(obj_selection_manager)) {
	show_debug_message("Selection manager does not exist.");
	exit;
}
old_object = selected_object;
selected_object = obj_selection_manager.get_selection();

if (old_object != selected_object) { panel_dirty = true };

if (selected_object == noone || !instance_exists(selected_object)) {
	// Deselected - hide the panel.
	active_tab = SELECT_TAB.NONE;
	selected_object = noone; //Clears a stale handle if instance doesn't exists.
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

// Refresh based on new settings
if (panel_dirty) {
    _refresh_panel_data();
    panel_dirty = false;
}