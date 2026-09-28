var _spd = 0.1; // small factor between 0 and 1 for smooth movement
var _t = 1 - power(1 - _spd, delta_time / (1000/60));

if (target_x != x || target_y != y) {
    x = lerp(x, target_x, _t);
    y = lerp(y, target_y, _t);
    
    // Snap when close enough to avoid infinite convergence
    if (abs(target_x - x) < 1 && abs(target_y - y) < 1) {
        x = target_x;
        y = target_y;
    }
}
