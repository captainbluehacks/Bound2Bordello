// _draw_tab_bar(px, py, pw)
// Draws the two-tab selector at the top of the panel.
// Uses active_tab (SELECT_TAB enum) to determine which tab is highlighted.
function _draw_tab_bar(_px, _py, _pw, _minion_count = 0, _minion_index = -1) {
    var TAB_H = 42;

    // ── Background strip ──────────────────────────────────────
    draw_set_colour(COL_TAB_BG);
    draw_rectangle(_px, _py, _px + _pw, _py + TAB_H, false);

    // ── Determine tab labels & which is active ────────────────
    var label_a, label_b;
    var a_active, b_active;
    var count_str = "";

    switch (active_tab) {
        case SELECT_TAB.ROOM:
            label_a = "◉ ROOM";       a_active = true;
            label_b = "MINIONS";      b_active = false;
            count_str = "(" + string(_minion_count) + ")";
            break;

        case SELECT_TAB.OBSTACLE:
            label_a = "◉ OBSTACLE";   a_active = true;
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

    var tab_w = _pw / 2;

    // ── Draw each tab ─────────────────────────────────────────
    for (var i = 0; i < 2; i++) {
        var tx = _px + i * tab_w;
        var is_active = (i == 0) ? a_active : b_active;
        var label     = (i == 0) ? label_a  : label_b;

        // Active highlight fill
        if (is_active) {
            draw_set_colour(COL_TAB_ACTIVE_BG);
            draw_rectangle(tx, _py, tx + tab_w, _py + TAB_H, false);
        }

        // Tab text (centred)
        draw_set_font(fnt_display_400);
        draw_set_halign(fa_center);
        draw_set_colour(is_active ? COL_INK : COL_TAB_INACTIVE);

        var text_y = _py + (TAB_H - string_height("M")) / 2;
        draw_text(tx + tab_w / 2, text_y, label);

        // Count badge (smaller, gold-dim, appended after the label)
        if (i == 1 && count_str != "") {
            draw_set_font(fnt_small);
            draw_set_colour(COL_GOLD_DIM);
            var main_w = string_width(label);
            draw_text(tx + tab_w / 2 + main_w / 2 + 4, text_y + 2, count_str);
        }

        // Active: gold underline (the "inset box-shadow" from CSS)
        if (is_active) {
            draw_set_colour(COL_GOLD);
            draw_line(tx + 1, _py + TAB_H - 2, tx + tab_w - 1, _py + TAB_H - 2);
        }

        // Vertical separator between tabs (skip after last)
        if (i < 1) {
            draw_set_colour(COL_LINE);
            draw_line(tx + tab_w, _py, tx + tab_w, _py + TAB_H);
        }
    }

    // ── Bottom border of the entire tab bar ───────────────────
    draw_set_colour(COL_LINE);
    draw_line(_px, _py + TAB_H, _px + _pw, _py + TAB_H);

    set_ui_defaults();
}
