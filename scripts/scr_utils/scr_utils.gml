enum COUNTER { 
	CHAMBER, CLIENT, MINION };


/// @description Generates unique ids.
function gen_unique_id(_type) {
    static counters = [0,0,0];
    counters[_type]++;
    return counters[_type];
}


