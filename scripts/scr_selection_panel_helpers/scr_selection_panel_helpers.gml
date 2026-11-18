// scr_draw_box(x1, y1, x2, y2, fill_col, border_col, [radius])
function scr_draw_box(_x1, _y1, _x2, _y2, _fill, _border, _rad = -1) {
    if (_rad < 0) {
        // Default radius (draw_roundrect uses a fixed small radius internally)
        draw_set_colour(_fill);
        draw_roundrect(_x1, _y1, _x2, _y2, false);
        draw_set_colour(_border);
        draw_roundrect(_x1, _y1, _x2, _y2, true);
    } else {
        // Explicit radius via draw_roundrect_ext
        draw_set_colour(_fill);
        draw_roundrect_ext(_x1, _y1, _x2, _y2, _rad, _rad, false);
        draw_set_colour(_border);
        draw_roundrect_ext(_x1, _y1, _x2, _y2, _rad, _rad, true);
    }
    
    set_ui_defaults();
}

// scr_draw_section_header(x, y, w, text) -> returns new y
function scr_draw_section_header(_x, _y, _w, _text) {
    draw_set_font(fnt_display_400);
    draw_set_colour(COL_GOLD);
    // Uppercase + letter-spacing (GameMaker doesn't have native letter-spacing,
    // so either bake it into the font or just uppercase):
    draw_text(_x, _y, string_upper(_text));
    
    var h = string_height("M");
    _y += h + 7;
    
    // Faded rule line under header
    draw_set_colour(COL_LINE);
    draw_line(_x, _y, _x + _w, _y);
    _y += 10;
    
	set_ui_defaults();
	
    return _y;
}


// scr_draw_breakdown_row(x, y, w, label, value_str, value_col, is_locked) -> returns new y
function scr_draw_breakdown_row(_x, _y, _w, _label, _val_str, _val_col, _locked = false) {
    if (_locked) draw_set_alpha(COL_LOCKED_ALPHA);
    
    draw_set_font(fnt_body_400);
    
    // Label (left)
    draw_set_colour(COL_INK_BODY);
    draw_text(_x, _y, _label);
    
    // Value chip (right-aligned rounded pill with tinted bg)
    var vw = string_width(_val_str) + 18;
    var vx = _x + _w - vw;
    var vy = _y - 2;
    var vh = string_height("M") + 5;
    
    // Tinted background (resource colour at low alpha)
	scr_draw_box(vx, vy, vx + vw, vy + vh, _get_resource_bg(_val_col), _val_col);
    
    // Value text
    draw_set_colour(_val_col);
    draw_text(vx + 9, _y, _val_str);
    
    if (_locked) draw_set_alpha(1);
    
    // Dotted separator below this row
    _y += string_height("M") + 5;
    draw_set_colour(COL_LINE);
    for (var dx = _x; dx < _x + _w - 4; dx += 6) {
        draw_point(dx, _y);
    }
    _y += 8;
    
	set_ui_defaults();
	
    return _y;
}


// scr_draw_tag_pill(x, y, text, variant) -> returns new x
// variant: TAG_PLAIN, TAG_QUIRK, TAG_UPGRADE
function scr_draw_tag_pill(_x, _y, _text, _variant = 0) {
    draw_set_font(fnt_small);
    
    var bg_col, border_col, text_col;
    switch (_variant) {
        case 1: bg_col = COL_QUIRK_BG;     border_col = COL_QUIRK_BORDER;     text_col = COL_QUIRK_TEXT; break;
        case 2: bg_col = COL_UPGRADE_BG;   border_col = COL_UPGRADE_BORDER;   text_col = COL_UPGRADE_TEXT; break;
        default: bg_col = COL_TAG_BG;      border_col = COL_TAG_BORDER;       text_col = COL_TAG_TEXT;
    }
    
    var tw = string_width(_text) + 16;
    var th = string_height("M") + 5;
    
    scr_draw_box(_x, _y, _x + tw, _y + th, bg_col, border_col, 9);
    
    draw_set_colour(text_col);
    draw_text(_x + 8, _y + 2, _text);
    
	set_ui_defaults();
	
    return _x + tw + 6;
}


// scr_draw_total_line(x, y, w, label, value_str, value_col) -> returns new y
function scr_draw_total_line(_x, _y, _w, _label, _val_str, _val_col) {
    // Solid gold top border (thicker than regular lines)
    draw_set_colour(COL_GOLD);
    draw_line(_x, _y, _x + _w, _y);
    _y += 10;
    
    draw_set_font(fnt_body_400);
    draw_set_halign(fa_left);
    draw_set_colour(COL_INK);
    draw_text(_x, _y, _label);
    
    // Value on the right (bold feel — use display font or just gold)
    draw_set_halign(fa_right);
    draw_set_colour(_val_col);
    draw_text(_x + _w, _y, _val_str);
    draw_set_halign(fa_left);
    
	set_ui_defaults();
	
    return _y + string_height("M") + 12;
}


// scr_draw_progress_bar(x, y, w, h, fraction)
function scr_draw_progress_bar(_x, _y, _w, _h = 13, _frac = 0.0) {
    // Track
    scr_draw_box(_x, _y, _x + _w, _y + _h, COL_BAR_BG, COL_BAR_BORDER, 7);
    
    // Fill (inset so it sits inside the border)
    var fill_w = (_w - 4) * clamp(_frac, 0, 1);
    if (fill_w > 2) {
        draw_set_colour(COL_BAR_FILL_L);
        draw_roundrect_ext(_x + 2, _y + 2, _x + 2 + fill_w, _y + _h - 2, 5, 5, false);
    }
    
    set_ui_defaults();
}


// scr_draw_button(x, y, w, h, text, is_primary) -> returns rect for hit-testing
function scr_draw_button(_x, _y, _w, _h = 34, _text, _primary = false) {
    var fill, border, text_col;
    if (_primary) {
        fill     = COL_BTN_PRI_TOP;
        border   = COL_BTN_PRI_BORDER;
        text_col = COL_BTN_PRI_TEXT;
    } else {
        fill     = COL_BTN_BG;
        border   = COL_BTN_BORDER;
        text_col = COL_BTN_TEXT;
    }
    
    scr_draw_box(_x, _y, _x + _w, _y + _h, fill, border, 5);
    
    draw_set_font(fnt_display_400);
    draw_set_colour(text_col);
    draw_set_halign(fa_center);
    draw_text(_x + _w / 2, _y + (_h - string_height("M")) / 2, _text);
    draw_set_halign(fa_left);
	
	set_ui_defaults();
}



// Helper: get the tinted background colour for a resource value chip
function _get_resource_bg(_col) {
    // Map known resource colours to their pre-computed bg constants
    if (_col == COL_CASH)        return COL_CASH_BG;
    if (_col == COL_LUST)        return COL_LUST_BG;
    if (_col == COL_HUMILIATION) return COL_HUMILIATION_BG;
    if (_col == COL_INFLUENCE)   return COL_INFLUENCE_BG;
    if (_col == COL_VALUE)       return COL_VALUE_BG;
    if (_col == COL_POWER)       return COL_POWER_BG;
    if (_col == COL_STOCK)       return COL_STOCK_BG;
    // Fallback: 13% alpha of the given colour
    return make_colour_alpha(_col, 0.13);
}
