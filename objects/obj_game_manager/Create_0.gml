//Layout Constants
global.floor_h = 640;
global.current_floor = 1;

// Define Globals
global.money=100;
global.lust_mana = 0;
global.fear_mana = 0;
global.humiliation_mana = 0;
global.nightly_clients = 0; 
show_debug_message("Manager is alive");

// Define our states using "Macros" (these are constants that don't change)
#macro STATE_DAY 0
#macro STATE_NIGHT 1
#macro STATE_RECKONING 2

global.current_state = STATE_DAY; // Start in Day mode


global.reckoning_data = {
	tax_pad: 0,
	clients_served: 0,
	boons_earned: 0
};


room_goto(rm_start);


