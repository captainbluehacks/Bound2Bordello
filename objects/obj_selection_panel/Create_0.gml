enum SELECT_TAB { NONE, ROOM, MINIONS, OBSTACLE }

// Make sure the panel sprite is available.
gml_pragma("MarkTagAsUsed", "panel");

// Define panel position
panel_w = sprite_get_width(spr_parchment_panel);
panel_h = sprite_get_height(spr_parchment_panel);

var _pad = 20; // Padding so we're not flush with right hand side of screen.

panel_x = display_get_gui_width() - panel_w - _pad;  // right side of screen
panel_y = 120;                              // below top resource bar

// Constant
obstacles = ["cluttered", "hazards", "rubble", "seals"];

// State variables (set externally when a chamber is selected)
selected_object = noone;
last_chamber = noone;
active_tab = SELECT_TAB.NONE;   // NONE, ROOM, MINIONS, OBSTACLE

// Place to store panel data.
// Function to refresh them is in scr_selection_panel_data
panel_data = {};
panel_dirty = false;
