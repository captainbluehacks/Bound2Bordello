/// Build an empty mansion grid and return it, stashing into global.mansion_map.
function test_setup_grid(_w = 10, _h = 8) {
    if (global.mansion_map != noone && is_ds_grid(global.mansion_map)) ds_grid_destroy(global.mansion_map);
    global.mansion_map = ds_grid_create(_w, _h);
    ds_grid_set_region(global.mansion_map, 0, 0, _w - 1, _h - 1, -1);
}

/// Create an obj_chamber at a grid cell and register it in the map (honouring size).
function test_place_chamber(_type, _gx, _gy, _size = ROOM_SIZE.SMALL) {
    var _inst = instance_create_layer(0, 0, mansion_layer.chamber, obj_chamber,
        { chamber_type: _type, chamber_size: _size, grid_x: _gx, grid_y: _gy });
    var _d = global.size_dims[_size];
    for (var x = 0; x < _d.w; x++)
        for (var y = 0; y < _d.h; y++)
            ds_grid_set(global.mansion_map, _gx + x, _gy + y, _inst);
    return _inst;
}

/// Build a guest/client instance with explicit fields (no RNG) so tests are deterministic.
function test_make_client(_name = "Guest", _tags = [], _backstory = "", _freq = 1.0) {
    var _c = create(0, 0, obj_client);
    _c.name            = _name;
    _c.tags            = array_copy(_tags);
    _c.backstory       = _backstory;
    _c.visit_frequency = _freq;
    _c.converted       = false;
    return _c;
}

/// Build a minion instance with explicit fields (no RNG) so tests are deterministic.
function test_make_minion(_tags = [], _quirk = "", _chamber = no, _is_friend = false) {
    var _m = create(0, 0, obj_minion);
    _m.tags           = array_copy(_tags);
    _m.quirk          = _quirk;
    _m.current_chamber= _chamber;
    _m.is_friend      = _is_friend;
    return _m;
}

/// Tear down all chamber/minion/client instances created during a test.
function test_cleanup_instances() {
    with (obj_chamber) instance_dummy(); // Note: using dummy or destroy based on GM preference
    with (obj_minion)  instance_destroy();
    with (obj_client)  instance_destroy();
}
