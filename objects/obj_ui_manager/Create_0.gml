// Layout constants
var _button_offset = 255;	// Button width 240 + 15 px pad.
var _bottom_bar_height = 140;

global.ui_blocked = false;
shiver_intensity = 1.5;


// Helper to simplify button creation
/// @description Build a UI button struct with position, size, sprite and action ID.
/// @param {string} _name Name of the button (may be empty for arrows).
/// @param {real} _x X position of the button.
/// @param {real} _y Y position of the button.
/// @param {sprite} _sprite Sprite to draw on the button.
/// @param {real} _frame Frame index of the sprite.
/// @param {enum UI_ACTION} _action Action ID fired when the button is clicked.
/// @param {real} [_w] Optional: width, defaults to 240.
/// @param {real} [_h] Optional: height, defaults to 120.
/// @return {map} The new button struct.
function create_btn(_name, _x, _y, _sprite, _frame, _action, _w=240, _h=120) {
    return {
        name: _name, x: _x, y: _y, w: _w, h: _h, 
        sprite: _sprite, frame: _frame, action_id: _action,
        offset_x: 0, offset_y: 0, offset_rot: 0, 
        hovering: false, clicked: false
    };
};

buttons = [
    create_btn("Self", GUI_W / 4, GUI_H - _bottom_bar_height + 10, s_default_button, 0, UI_ACTION.CENTER_YOU),
    create_btn("Peon", 300 + GUI_W / 4, GUI_H - _bottom_bar_height + 10, s_default_button, 0, UI_ACTION.NEXT_MINION),
    create_btn("Done", GUI_W - _button_offset , GUI_H - _bottom_bar_height + 10, s_default_button, 0, UI_ACTION.DONE)
];

// Arrows use the same structure for consistency in the loop
arrows = [
    create_btn("", GUI_W / 2, 20, s_scroll_arrow, UI_DIRECTION_ARROW.UP ,UI_ACTION.UP, 50, 50),
    create_btn("", GUI_W / 2, GUI_H - _bottom_bar_height - 70, s_scroll_arrow, UI_DIRECTION_ARROW.DOWN, UI_ACTION.DOWN, 50, 50),
    create_btn("", 20, (GUI_H - _bottom_bar_height) / 2, s_scroll_arrow, UI_DIRECTION_ARROW.LEFT, UI_ACTION.LEFT, 50, 50),
    create_btn("", GUI_W - 70, (GUI_H - _bottom_bar_height) / 2, s_scroll_arrow, UI_DIRECTION_ARROW.RIGHT, UI_ACTION.RIGHT, 50, 50)
];

/// @description Handle a UI_ACTION from a clicked button. DONE ends the turn;
/// UP/DOWN/LEFT/RIGHT nudge obj_camera.scroll_offset by half a floor height
/// (global.floor_h / 2); CENTER_YOU and NEXT_MINION are currently no-ops.
/// @param {enum UI_ACTION} _actionId The action ID to process.
function process_button_action(_actionId) {
	switch (_actionId) {
		case UI_ACTION.CENTER_YOU:
		
		break;
		
		case UI_ACTION.DONE:
			obj_game_manager.end_turn();
		break;
		
		case UI_ACTION.NEXT_MINION:
		
		break;
		
		case UI_ACTION.UP:
			obj_camera.scroll_offset.y -= global.floor_h / 2;
		break;
		
		case UI_ACTION.DOWN:
			obj_camera.scroll_offset.y += global.floor_h / 2;		
		break;
		
		case UI_ACTION.LEFT:
			obj_camera.scroll_offset.x -= global.floor_h / 2;
		break;
		
		case UI_ACTION.RIGHT:
			obj_camera.scroll_offset.x += global.floor_h / 2;
		break;
	}
	
};

/// @description Draw a resource icon: the sprite stretched into a square with
/// shadowed text over it. Restores UI defaults when done.
/// @param {sprite} _sprite Sprite to draw as the icon background.
/// @param {real} _sx X position of the icon.
/// @param {real} _sy Y position of the icon.
/// @param {real} _size Width and height of the stretched sprite.
/// @param {font} _font Font used for the value text.
/// @param {real} _tx X position of the value text.
/// @param {real} _ty Y position of the value text.
/// @param {string} _value Value to display over the icon (stringified).
function draw_icon(_sprite, _sx, _sy, _size, _font, _tx, _ty, _value) {
	
	draw_set_font(_font);
	draw_set_alpha(0.9);
	
	draw_sprite_stretched(_sprite, 0, _sx, _sy, _size, _size);
    
	draw_set_alpha(0.95);
	
    // Shadow text
    draw_set_colour(c_white);
    draw_text(_tx + 1, _ty  + 1, string(_value));
    
    // Main text  
    draw_set_colour($2A1A10);
    draw_text(_tx, _ty, string(_value));
    
	set_ui_defaults();
}
