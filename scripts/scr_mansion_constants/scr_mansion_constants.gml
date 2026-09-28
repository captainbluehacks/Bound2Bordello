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

}
