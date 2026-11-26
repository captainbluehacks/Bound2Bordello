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

/// @description Set up global mansion constants: global.size_dims, an array of
/// {w, h, name} structs for the small (1x1), medium (2x1) and large (2x2) room sizes.
function scr_mansion_constants() {

	// Define the room sizes
	global.size_dims = [
		{ w : 1, h : 1, name : "small"},
		{ w : 2, h : 1, name : "medium"},
		{ w : 2, h : 2, name : "large"}
		] ;

}
