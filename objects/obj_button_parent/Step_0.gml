hovering = position_meeting(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), id);

if (hovering && mouse_check_button_pressed(mb_left)) 
{
	clicked = true;
}


if (mouse_check_button_released(mb_left)) 
{
    clicked = false;
    if (hovering) 
    {
        audio_play_sound(snd_button, 1, false);
        // Instead of activate_button(), tell the manager!
		process_button_action(action_id)
    }
} 


// --- SHIVER LOGIC ---
if (hovering && !clicked) {
    // Randomly jitter between -intensity and +intensity
    offset_x = random_range(-shiver_intensity, shiver_intensity);
    offset_y = random_range(-shiver_intensity, shiver_intensity);
} 
// --- SLIDE LOGIC ---
else if (clicked) {
    // Slide slightly down and right (like a piece of paper being pressed)
    offset_x = lerp(offset_x, 4, 0.2); 
    offset_y = lerp(offset_y, 4, 0.2);
	offset_rot = lerp(offset_rot, 5, 0.2); 
} 
else {
    // Smoothly return to center (0,0) when not interacting
    offset_x = lerp(offset_x, 0, 0.2);
    offset_y = lerp(offset_y, 0, 0.2);
	offset_rot = lerp(offset_rot, 0, 0.2); 
}