/// @description Refreshes the cache of data needed for selection panel.
/// Updates the contents of panel data in obj_selection_panel. 
/// Should not be called directly - use obj_selection_panel.mark_dirty().
function _refresh_panel_data() {
    if (!instance_exists(obj_selection_panel) || 
		!instance_exists(obj_selection_panel.selected_object) ||
		obj_selection_panel.selected_object == noone ) return;
	
    switch (active_tab) {
		case SELECT_TAB.NONE:
			panel_data = {};
			break;
        case SELECT_TAB.ROOM:
			_get_chamber_data(selected_object);
            break;
        case SELECT_TAB.MINIONS:
			// Guard for unassigned minions.
			if (selected_object.current_chamber == noone) {
				show_debug_message("Found Minion without an assigned room.");
				panel_data = {};
				return;
			}
			// Now cache the contents of this room.
            _get_chamber_data(selected_object.current_chamber);
            break;
		case SELECT_TAB.OBSTACLE:
			// ...
			break;
    }
}

/// @description Caches the relevant data needed to display a selection panel.
/// @param {instance} _chamber The obj_chamber that was directly or indirectly selected.
function _get_chamber_data(_chamber) {
	if (_chamber == noone || !instance_exists(_chamber)) return;	
	
	struct_set(panel_data, "chamber_type", scr_get_chamber_type(_chamber.chamber_type));
	struct_set(panel_data, "chamber_data", scr_calculate_chamber(_chamber));
	struct_set(panel_data, "effective_tags", scr_get_effective_tags(_chamber));
			
	// Pre-load minions so tab-switching is free
	var _minions = [];
	for (var i = 0; i < array_length(_chamber.minions); i++) {
		if (_chamber.minions[i] != noone) {
			array_push(_minions, _chamber.minions[i]);
		}
	}
	struct_set(panel_data, "minions", _minions);
}

/// @descripion Marks the selection panel dirty.
/// Use whenever a mutation is applied to either the room data, or a minion within the room. 
/// This would include adding a new minion to the room.
function mark_dirty() {
	if (!instance_exists(obj_selection_panel)) exit ;
	
	obj_selection_panel.panel_dirty = true;
}