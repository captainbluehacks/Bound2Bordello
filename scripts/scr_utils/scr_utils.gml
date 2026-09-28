enum COUNTER { 
	CHAMBER, CLIENT, MINION, LENGTH };


/// @description Generates unique ids when provided by a COUNTER.<enum>
/// @returns Real  
function gen_unique_id(_type) {
	if (_type < 0 && _type > COUNTER.LENGTH) {
		show_debug_message("Asked to update Invalid Counter");
		return -1;
	}
	
    static counters = [0,0,0];
    counters[_type]++;
    return counters[_type];
}


