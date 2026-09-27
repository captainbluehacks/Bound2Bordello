// For now a simple animation. Later we'll use rotation to move
var _spd = 3;

if (target_x != x) {
	x = lerp(target_x, x, _spd);
	y = lerp(target_y, y, _spd);
}