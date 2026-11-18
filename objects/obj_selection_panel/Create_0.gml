enum SELECT_TAB { ROOM, MINIONS, OBSTACLE }

// obj_ui_chamber_panel - Create Event
panel_x = display_get_gui_width() - 420;  // right side of screen
panel_y = 80;                              // below top resource bar
panel_w = 400;
panel_h = display_get_gui_height() - panel_y - 60;

// State variables (set externally when a chamber is selected)
selected_chamber_id = noone;
selected_minion_id  = noone;
active_tab          = SELECT_TAB.ROOM;            // ROOM, MINIONS, OBSTACLE