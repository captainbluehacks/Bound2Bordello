var _selected_obj = obj_selection_manager.get_selection();

if (_selected_obj == noone && !instance_exists(_selected_obj)) {
	// Deselected - hide the panel.
	selected_chamber_id = noone;
	selected_minion_id  = noone;
}
else if (_selected_obj.object_index == obj_chamber) {
	selected_chamber_id = _selected_obj;
}
else if (_selected_obj.object_index == obj_minion) {
	selected_minion_id = _selected_obj;
}