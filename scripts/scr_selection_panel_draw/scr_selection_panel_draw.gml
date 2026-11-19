// _draw_tab_bar(px, py, pw)
// Draws the two-tab selector at the top of the panel.
// Uses active_tab (SELECT_TAB enum) to determine which tab is highlighted.
function _draw_tab_bar(_px, _py, _pw, _minion_count = 0, _minion_index = -1) {
    var TAB_H = 42;

    // ── Background strip ──────────────────────────────────────
	var _padding = 20;
    draw_set_colour(COL_TAB_BG);
	draw_set_alpha(COL_TAB_BG_ALPHA);
    draw_rectangle(_px + _padding, _py, _px + _pw - _padding, _py + TAB_H, false);
	draw_set_alpha(1);
	
    // ── Determine tab labels & which is active ────────────────
    var label_a, label_b;
    var a_active, b_active;
    var count_str = "";

    switch (active_tab) {
        case SELECT_TAB.ROOM:
            label_a = "• ROOM";       a_active = true;
            label_b = "MINIONS";      b_active = false;
            count_str = "(" + string(_minion_count) + ")";
            break;

        case SELECT_TAB.OBSTACLE:
            label_a = "• OBSTACLE";   a_active = true;
            label_b = "MINIONS";      b_active = false;
            count_str = "(" + string(_minion_count) + ")";
            break;

        case SELECT_TAB.MINIONS:
            label_a = "ROOM";         a_active = false;
            label_b = "MINION";       b_active = true;
            // e.g. "(1/3)" — current index / total, or just the count
			var _prefix = (_minion_count == 0) ? "" : (string(_minion_index) + "/");
			count_str = "(" + _prefix + string(_minion_count) + ")";
            break;

        default:
            return; // SELECT_TAB.NONE — don't draw
    }

    var _inner_x = _px + _padding;
	var _inner_w = _pw - (_padding * 2);
	var tab_w    = _inner_w / 2;

    // ── Draw each tab ─────────────────────────────────────────
    for (var i = 0; i < 2; i++) {
        var tx = _inner_x + i * tab_w; 
        var is_active = (i == 0) ? a_active : b_active;
        var label     = (i == 0) ? label_a  : label_b;

        // Active highlight fill
        if (is_active) {
            draw_set_colour(COL_TAB_ACTIVE_BG);
			draw_set_alpha(COL_TAB_ACTIVE_BG_ALPHA);
            draw_rectangle(tx, _py, tx + tab_w, _py + TAB_H, false);
			draw_set_alpha(1);
        }

		// Vertical Centered
		var text_y = _py + (TAB_H - string_height("M")) / 2;
		
        // Tab text (centred)
		if (i == 1 && count_str != "") {
			var main_w = string_width(label);
			var cnt_w  = string_width(count_str);
			var gap    = 5;
			var total_w = main_w + gap + cnt_w;
			var start_x = tx + tab_w / 2 - total_w / 2;
			
			draw_set_halign(fa_left);
			draw_set_valign(fa_top);
			draw_set_font(fnt_display_400);
			draw_set_colour(is_active ? COL_INK : COL_TAB_INACTIVE);
			draw_text(start_x, text_y, label);

			draw_set_font(fnt_small);
			draw_text(start_x + main_w + gap, text_y + 2, count_str);
		} else {
			// No badge — just centre the label as before
			draw_set_valign(fa_top);
			draw_set_halign(fa_center);
			draw_set_font(fnt_display_400);
			draw_set_colour(is_active ? COL_INK : COL_TAB_INACTIVE);
			draw_text(tx + tab_w / 2, text_y, label);
		}

        // Active: gold underline (the "inset box-shadow" from CSS)
        if (is_active) {
            draw_set_colour(COL_GOLD);
            draw_rectangle(tx, _py + TAB_H - 3, tx + tab_w, _py + TAB_H, false);
        }

        // Vertical separator between tabs (skip after last)
        if (i < 1) {
            draw_set_colour(COL_LINE);
            draw_line(tx + tab_w, _py, tx + tab_w, _py + TAB_H);
        }
    }

    // ── Bottom border of the entire tab bar ───────────────────
    draw_set_colour(COL_LINE);
    draw_line(_inner_x, _py + TAB_H, _inner_x + _inner_w, _py + TAB_H);

	// After drawing everything else, frame the whole tab bar
	draw_set_colour(COL_LINE);
	draw_rectangle(_inner_x, _py, _inner_x + _inner_w, _py + TAB_H, true);  // outline only

    set_ui_defaults();
}
