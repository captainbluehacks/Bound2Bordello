// obj_ui_chamber_panel - Draw GUI Event
if (selected_chamber_id == noone || !instance_exists(selected_chamber_id)) exit;

var px = panel_x;
var py = panel_y;
var pw = panel_w;
var ph = panel_h;

// 1. Parchment background (a sprite with torn edges)
draw_sprite(spr_parchment_panel, 1, px, py);

// 2. Tab bar at top
// _draw_tab_bar(px, py, pw);

// 3. Content area (inset from parchment edges)
var content_x = px + 20;
var content_y = py + 50;   // below tabs
var content_w = pw - 40;
var y_cursor  = content_y;

// 4. Draw the active tab's content
switch (active_tab) {
    case SELECT_TAB.ROOM:
        // y_cursor = _draw_room_content(content_x, y_cursor, content_w);
        break;
    case SELECT_TAB.MINIONS:
        // y_cursor = _draw_minion_content(content_x, y_cursor, content_w);
        break;
    case SELECT_TAB.OBSTACLE:
        // y_cursor = _draw_obstacle_content(content_x, y_cursor, content_w);
        break;
}

// 5. Bottom action buttons (anchored to bottom of panel)
// _draw_action_buttons(px, py + ph - 40, pw);
