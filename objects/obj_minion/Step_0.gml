var _spd = 0.1; // small factor between 0 and 1 for smooth movement

if (target_x != x || target_y != y) {
    x = lerp(x, target_x, _spd);
    y = lerp(y, target_y, _spd);
    
    // Snap when close enough to avoid infinite convergence
    if (abs(target_x - x) < 1 && abs(target_y - y) < 1) {
        x = target_x;
        y = target_y;
    }
}
