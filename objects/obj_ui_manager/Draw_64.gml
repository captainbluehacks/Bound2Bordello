
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
var _cell = 133;
var _size = 80;
var _offset = 10 ;

// Left Hand side
draw_sprite(spr_top_left_resources, 0, _offset, 10);

// Font setup
draw_set_font(fnt_score_gothic);
draw_set_colour($2A1A10);
draw_set_alpha(0.9);
draw_set_halign(fa_center);
draw_set_valign(fa_center);

// Value
draw_sprite_stretched(spr_value, 0, (_cell - _size) / 2 + _offset, 15, _size, _size);
draw_set_colour(c_white);
draw_text(1 + _offset + _cell / 2, 111, string(global.primary_resources.value));
draw_set_colour($2A1A10);
draw_text(_offset + _cell / 2, 110, string(global.primary_resources.value));


// Power
draw_sprite_stretched(spr_power, 0, _cell + (_cell - _size) / 2 + _offset, 15, _size, _size);
draw_set_colour(c_white);
draw_text(1 + _offset + _cell + _cell / 2, 111, string(global.primary_resources.power));
draw_set_colour($2A1A10);
draw_text(_offset + _cell + _cell / 2, 110, string(global.primary_resources.power));

// Stock
draw_sprite_stretched(spr_stock, 0, _cell * 2 + (_cell - _size) / 2 + _offset, 15, _size, _size);
draw_set_colour(c_white);
draw_text(1 + _offset + _cell * 2 + _cell  / 2, 111, string(global.primary_resources.stock));
draw_set_colour($2A1A10);
draw_text(_offset + _cell * 2 + _cell  / 2, 110, string(global.primary_resources.stock));

// End of Left Panel

// Constants
_cell = 860 / 10;
_size = 70;
_offset = GUI_W - 890;

// Right Hand Side
draw_sprite(spr_top_right_resources, 0, _offset, 10);

_offset = _offset + 20;

// Font setup
draw_set_font(fnt_resource_gothic);
draw_set_halign(fa_left);
draw_set_valign(fa_middle);

// Lust
draw_sprite_stretched(spr_lust, 0, _offset, 15, _size, _size);
draw_set_colour(c_white);
draw_text(1 + _offset + _cell, 59, string(global.secondary_resources.lust));
draw_set_colour($2A1A10);
draw_text(_offset + _cell, 58, string(global.secondary_resources.lust));


// Humiliation
draw_sprite_stretched(spr_humiliation, 0, _offset + _cell * 2, 15, _size, _size);
draw_set_colour(c_white);
draw_text(1 + _offset + _cell * 3, 59, string(global.secondary_resources.humiliation));
draw_set_colour($2A1A10);
draw_text(_offset + _cell * 3, 58, string(global.secondary_resources.humiliation));


// Fear
draw_sprite_stretched(spr_fear, 0, _offset + _cell * 4, 15, _size, _size);
draw_set_colour(c_white);
draw_text(1 + _offset + _cell * 5, 59, string(global.secondary_resources.fear));
draw_set_colour($2A1A10);
draw_text(_offset + _cell * 5, 58, string(global.secondary_resources.fear));

// Cash
draw_sprite_stretched(spr_cash, 0, _offset + _cell * 6, 15, _size, _size);
draw_set_colour(c_white);
draw_text(1 + _offset + _cell * 7, 59, string(global.secondary_resources.cash));
draw_set_colour($2A1A10);
draw_text(_offset + _cell * 7, 58, string(global.secondary_resources.cash));

// Influence
draw_sprite_stretched(spr_influence, 0, _offset + _cell * 8, 15, _size, _size);
draw_set_colour(c_white);
draw_text(1 + _offset + _cell * 9, 59, string(global.secondary_resources.influence));
draw_set_colour($2A1A10);
draw_text(_offset + _cell * 9, 58, string(global.secondary_resources.influence));