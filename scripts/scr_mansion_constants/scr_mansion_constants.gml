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

		
	// Create a grid for tracking chambers.
	var _grid_width = 10;
	var _grid_height = 8;
	
	// Shared grid tracking which chamber instance occupies each cell.
	// Global because it is read by many objects (chambers, minions) via the
	// query functions below, not just obj_mansion_manager.
	global.mansion_map = ds_grid_create(_grid_width, _grid_height);
		
	// Set everything to unassigned.
		ds_grid_set_region(global.mansion_map, 0, 0, _grid_width -1, _grid_height - 1, -1);
}
