function _refresh_panel_data() {
    if (selected_object == noone || !instance_exists(selected_object)) return;
    
    switch (active_tab) {
		case SELECT_TAB.NONE:
			panel_data = {};
        case SELECT_TAB.ROOM:
			_get_chamber_data(selected_object);
            break;
        case SELECT_TAB.MINIONS:
            _get_chamber_data(selected_object.current_chamber);
            break;
		case SELECT_TAB.OBSTACLE:
			// ...
			break;
    }
}

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