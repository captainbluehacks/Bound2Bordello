// Guard against missing object
if (!instance_exists(obj_selection_manager)) {
	show_debug_message("Selection manager does not exist.");
	exit;
}

// Get current selection
selected_object = obj_selection_manager.get_selection();

// Determine which tab should be active
if (selected_object == noone || !instance_exists(selected_object)) {
	// Deselected - hide the panel.
	active_tab = SELECT_TAB.NONE;
	selected_object = noone; //Clears a stale handle if instance doesn't exists.
}
else if (selected_object.object_index == obj_chamber) {
	active_tab = array_contains(obstacles, selected_object.chamber_type) 
		? SELECT_TAB.OBSTACLE : SELECT_TAB.ROOM;
}
else if (selected_object.object_index == obj_minion) {
	active_tab = SELECT_TAB.MINIONS;
}

// Only dirty when the data source actually changed
if (active_tab == SELECT_TAB.NONE) {
    if (last_chamber != noone) {
        last_chamber = noone;
        panel_dirty  = true;   // triggers the reset-to-{} case
    }
} else if (active_tab == SELECT_TAB.OBSTACLE || active_tab == SELECT_TAB.ROOM) {
    if (selected_object != last_chamber) {
        last_chamber = selected_object;
        panel_dirty  = true;
    }
} else if (active_tab == SELECT_TAB.MINIONS) {
    // Minion belongs to a chamber — only re-fetch if that chamber changed,
    // or if we didn't already cache minions for it.
    var minion_room = selected_object.current_chamber;
    if (minion_room != last_chamber) {
        last_chamber = minion_room;
        panel_dirty  = true;
    }
}


// Refresh based on new settings
if (panel_dirty) {
    _refresh_panel_data();
    panel_dirty = false;
}