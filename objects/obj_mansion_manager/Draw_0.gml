if (selected_obj != noone && instance_exists(selected_obj) && selected_obj.object_index == obj_chamber) {

	var _result = scr_calculate_chamber(selected_obj);

	var _x = selected_obj.x;
	var _y = selected_obj.y;

	draw_text(_x, _y, "=== " + selected_obj.chamber_type + " ===");
	_y += 24;

	for (var i = 0; i < array_length(_result.lines); i++) {
		var _line = _result.lines[i];

		// Draw the label and description	
		draw_text(_x, _y, _line.detail);
		_y += 16;

		// Draw each resource effect as "+5 Lust Mana" etc.	
		var _keys = struct_get_names(_line.effects);
		for (var k = 0; k < array_length(_keys); k++) {
			draw_text(_x + 12, _y, "+" + string(_line.effects[_keys[k]]) + " " + scr_resource_display_name(_keys[k]));
			_y += 14;
		}
		_y += 8;  // spacing between lines
	}

	// Total
	draw_text(_x, _y, "--- TOTAL ---");
	_y += 20;
	var _total_keys = struct_get_names(_result.total);
	for (var i = 0; i < array_length(_total_keys); i++) {
		draw_text(_x, _y, scr_resource_display_name(_total_keys[i]) + ": " + string(_result.total[_total_keys[i]]));
		_y += 16;
	}

}
