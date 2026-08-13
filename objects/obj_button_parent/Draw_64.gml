
// Use local variables for final draw position
var draw_x = x + offset_x;
var draw_y = y + offset_y;

// 1. Draw the button sprite at the offset position
draw_sprite_ext(sprite_index, image_index, draw_x, draw_y, 1, 1, offset_rot, c_white, 1);

// 2. Draw the text at the same offset position
if (button_text != "" && button_text != undefined) 
{
    draw_set_font(fnt_button_gothic);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // Use draw_x and draw_y for all layers of the glow
    draw_text_transformed_color(draw_x, draw_y, button_text, 1.1, 1.1, 0, c_purple, c_purple, c_purple, c_purple, 1);
    draw_text_transformed_color(draw_x, draw_y, button_text, 1, 1, 0, c_fuchsia, c_fuchsia, c_fuchsia, c_fuchsia, 1);
    draw_text_transformed_color(draw_x, draw_y, button_text, 0.95, 0.95, 0, c_white, c_white, c_white, c_white, 1);
}