enum FLOOR {
	BASEMENT,
	GROUND,
	FIRST,
	ATTIC,
	LENGTH
}

enum ROOM_SIZE {
    SMALL,   // 1x1
    MEDIUM,  // 2x1
    LARGE    // 2x2
}; 

function scr_mansion_constants() {

	// Define the room sizes
	global.size_dims = [
		{ w : 1, h : 1, name : "small"},
		{ w : 2, h : 1, name : "medium"},
		{ w : 2, h : 2, name : "large"}
		] ;

	// Shared grid tracking which chamber instance occupies each cell.
	// Global because it is read by many objects (chambers, minions) via the
	// query functions below, not just obj_mansion_manager.
	global.mansion_map = noone;
}