/// @description

// First the sky add the 6 sky tiles

// --- SKY LAYOUT (3 Columns x 2 Rows) ---
var sky_w = 1920;
var sky_h = 1130;

for (var i = 0; i < 6; i++) {
    // Calculate column (0, 1, or 2) and row (0 or 1)
    var col = i % 3;      // Remainder: 0,1,2, 0,1,2...
    var row = i div 3;    // Integer division: 0,0,0, 1,1,1...

    var posX = col * sky_w;
    var posY = row * sky_h;

    var sky = layer_sprite_create(bg_layer, posX, posY, spr_sky_day);
    layer_sprite_index(sky, fixed.sky + i);
}

// --- UNDERGROUND LAYOUT (3 Columns x 1 Row) ---
var ug_w = 1920;
var ug_y_start = 2260; // The vertical start point for the underground section

for (var j = 0; j < 3; j++) {
    var posX = j * ug_w;

    // Place them all at the same Y level, but shift X by 1920 each time
    var underground = layer_sprite_create(bg_layer, posX, ug_y_start, spr_background_underground);
    layer_sprite_index(underground, fixed.underground + j);
}