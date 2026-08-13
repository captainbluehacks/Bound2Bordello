
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

display_write_all_specs();