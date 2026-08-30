//Layout Constants
global.floor_h = 640;
global.current_floor = 1;

// Resources
global.primary_resources = { value : 0, power : 0, stock :0 };
global.secondary_resources = { cash : 0, lust : 0, humilliation : 0, fear : 0, influence : 0 };

// Time Tracking
enum period { day, night, reckoning };
enum season { spring, summer, autumn, winter };

current_season = season.spring; // We start in spring.
cycle = 1;                      // Cycle goes from 1 to 12
current_period = period.day;    // Start in Day mode

// Helper functions

get_period = function() {
	return current_period ;
};

get_season = function() {
	return current_season ;
};

end_turn = function(){
	
	if (current_period == period.day) {
		// Carry out end of day actions
		show_debug_message("End of Day " + string(cycle));
		
		current_period = period.night;
	} else if (current_period == period.night) {
		// Carry out end of day actions
		show_debug_message("End of Night " + string(cycle));
		
		current_period = period.reckoning;
	} else {
		// Carry out end of day actions
		show_debug_message("End of Reckoning " + string(cycle));
		
		if (cycle < 12) {
			cycle += 1;
		} else {
			// Carry out End of Cycle Actions
			show_debug_message("End of Cycle");
			
			if (current_season < 3) {
				current_season += 1;
				cycle = 1;
			} else {
				// Carry out End of Game Actions
				show_debug_message("End of Game Reached");
			}
		}		
		
		current_period = period.day;	
	}
};


room_goto(rm_start);


