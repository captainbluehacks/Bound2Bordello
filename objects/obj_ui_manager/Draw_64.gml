
// Background & Dividers
draw_sprite_stretched(spr_ui_panel_bg, 0, 0, 0, GUI_W, GUI_H);

var all_elements = array_concat(buttons, arrows);

for (var i = 0; i < array_length(all_elements); i++) {
    var btn = all_elements[i];
    var dx = btn.x + btn.offset_x;
    var dy = btn.y + btn.offset_y;

    draw_sprite_ext(btn.sprite, btn.frame, dx, dy, 1, 1, btn.offset_rot, c_white, 1);
    
    if (btn.name != "") {
        draw_set_font(fnt_button_gothic);
		draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
		draw_text_transformed_colour(dx + btn.w / 2, dy + btn.h / 2, btn.name, 1, 1, 0, #101010, #101010, #101010, #101010, 1);
    }
}

// Resource Panels

// Constants
var _cell = 133;	// Parchment is 400px. We have 3 icons for this section. 400 /3 == 133.
var _size = 80;		// chosen width of icon. 80 looks right after experimentation 
var _offset = 10 ;  // How much padding to give the parchment.
var _sprite_y = 15; // 10 pad from top of screen + 5px padding for the icon.
var _value_y = 110;	// 10 pad from top of screen + 10px top and bottom of icon + 80 icon + 10 pad.


// Left Hand side
draw_sprite(spr_top_left_resources, 0, _offset, 10);

// Position setup
draw_set_halign(fa_center);
draw_set_valign(fa_center);

// Draw 3 icons - Value, Power, Stock.

draw_icon(spr_value, (_cell - _size) / 2 + _offset, _sprite_y, _size, 
	fnt_score_gothic,  _offset + _cell / 2, _value_y, global.primary_resources.value);

draw_icon(spr_power, _cell + (_cell - _size) / 2 + _offset, _sprite_y, _size, 
	fnt_score_gothic,  _offset + 1.5 *_cell, _value_y, global.primary_resources.power);
	
draw_icon(spr_stock,  _cell * 2 + (_cell - _size) / 2 + _offset, _sprite_y, _size, 
	fnt_score_gothic,  _offset + 2.5 * _cell, _value_y, global.primary_resources.stock);


// End of Left Panel

// Constants
_cell = 860 / 10;		// Parchment is 880. Subtract 10px for padding. We have 10 icons for this section.
_size = 70;				// Chosen width of icon. 70 looks good after experimentation.
_offset = GUI_W - 890;	// Align parchment 10 pixels from right hand side.
_sprite_y = 15; // 10 pad from top of screen + 5px padding for the icon.
_value_y = 59;	// Calculated so midpoint of text aligns with midpoint of icon.

// Right Hand Side
draw_sprite(spr_top_right_resources, 0, _offset, 10);

_offset = _offset + 20;	// Tweak offset by double padding to place icons.

// Position setup
draw_set_halign(fa_left);
draw_set_valign(fa_middle);

// Create icons for our 5 resources. Lust, Humiliation, Fear, Cash and Influence.
// Text follows icons here, so x value each object just add a cell to the previous total.

draw_icon(spr_lust, _offset, _sprite_y, _size, 
	fnt_resource_gothic, _offset + _cell, _value_y, global.secondary_resources.lust);

draw_icon(spr_humiliation, _offset + _cell * 2, _sprite_y, _size, 
	fnt_resource_gothic, _offset + _cell * 3, _value_y, global.secondary_resources.humiliation);

draw_icon(spr_fear, _offset + _cell * 4, _sprite_y, _size, 
	fnt_resource_gothic, _offset + _cell * 5, _value_y, global.secondary_resources.fear);

draw_icon(spr_cash, _offset + _cell * 6, 15, _size, 
	fnt_resource_gothic, _offset + _cell * 7, 59, global.secondary_resources.cash);

draw_icon(spr_influence, _offset + _cell * 8, 15, _size, 
	fnt_resource_gothic, _offset + _cell * 9, 59, global.secondary_resources.influence);
