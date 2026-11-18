enum COUNTER { 
	CHAMBER, CLIENT, MINION, LENGTH };


/// @description Generates unique ids when provided by a COUNTER.<enum>
/// @returns Real  
function gen_unique_id(_type) {
	if (_type < 0 || _type >= COUNTER.LENGTH) {
		show_debug_message("Asked to update Invalid Counter");
		return -1;
	}
	
    static counters = [0,0,0];
    counters[_type]++;
    return counters[_type];
}

/// @description Sets colour, alpha and font back to defaults.
function set_ui_defaults() {
    draw_set_font(fnt_body_400);
    draw_set_colour(COL_INK);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
}