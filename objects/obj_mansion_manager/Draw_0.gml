var _sel = obj_selection_manager.get_selection();

if (_sel != noone && instance_exists(_sel) && _sel.object_index == obj_chamber) {
	
	var _result = scr_calculate_chamber(_sel);

	var _x = x;
	var _y = y;

	draw_text(_x, _y, "=== " + selected_chamber.display_name + " ===");
	_y += 24;

	for (var i = 0; i < array_length(_result.lines); i++) {
		var _line = _result.lines[i];
    
		// Draw the label and description
		draw_text(_x, _y, _line.detail);
		_y += 16;
    
		// Draw each resource effect as "+5 Lust Mana" etc.
		var _keys = map_get_keys(_line.effects);
		for (var k = 0; k < array_length(_keys); k++) {
			draw_text(_x + 12, _y, "+" + string(_line.effects[_keys[k]]) + " " + scr_resource_display_name(_keys[k]));
			_y += 14;
		}
		_y += 8;  // spacing between lines
	}

	// Total
	draw_text(_x, _y, "--- TOTAL ---");
	_y += 20;
	var _total_keys = map_get_keys(_result.total);
	for (var i = 0; i < array_length(_total_keys); i++) {
		draw_text(_x, _y, scr_resource_display_name(_total_keys[i]) + ": " + string(_result.total[_total_keys[i]]));
		_y += 16;
	}
	
}