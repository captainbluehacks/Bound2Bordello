global.ui_blocked = false;
var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);


// Combine arrays for a single processing loop
var all_elements = array_concat(buttons, arrows);

for (var i = 0; i < array_length(all_elements); i++) {
    var btn = all_elements[i];
    
    // 1. Collision Check
    btn.hovering = (mx >= btn.x && mx <= btn.x + btn.w && my >= btn.y && my <= btn.y + btn.h);
    
    if (btn.hovering) {
        global.ui_blocked = true;
        if (mouse_check_button_pressed(mb_left)) btn.clicked = true;
    }

    // 2. Interaction Logic
    if (btn.clicked && mouse_check_button_released(mb_left)) {
        if (btn.hovering) {
            audio_play_sound(snd_button, 1, false);
            process_button_action(btn.action_id);
        }
        btn.clicked = false;
    }

    // 3. Animation Logic (Shiver/Slide)
    if (btn.hovering && !btn.clicked) {
        btn.offset_x = random_range(-shiver_intensity, shiver_intensity);
        btn.offset_y = random_range(-shiver_intensity, shiver_intensity);
    } else if (btn.clicked) {
        btn.offset_x = lerp(btn.offset_x, 4, 0.2); 
        btn.offset_y = lerp(btn.offset_y, 4, 0.2);
        btn.offset_rot = lerp(btn.offset_rot, 5, 0.2); 
    } else {
        btn.offset_x = lerp(btn.offset_x, 0, 0.2);
        btn.offset_y = lerp(btn.offset_y, 0, 0.2);
        btn.offset_rot = lerp(btn.offset_rot, 0, 0.2); 
    }
}