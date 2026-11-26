/// @description Returns the visual centre of this instance's sprite as an {x,y} struct — the point the camera focuses on when selected. No params.
/// @return {map} Struct with x/y at the centre of the instance's bounding box.
function get_focus_point() {
	return {x: x + sprite_width / 2, y: y + sprite_height / 2};
}
