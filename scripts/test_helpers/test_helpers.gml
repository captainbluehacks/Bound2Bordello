/// @description Shared fixtures / builders for GMTL test suites.
/// Keep tests DRY: build grids, chambers, minions and clients with explicit
/// (non-RNG) values so assertions are deterministic.

// ---------------------------------------------------------------------------
// Grid
// ---------------------------------------------------------------------------

/// Build an empty mansion grid and stash it into global.mansion_map.
function test_setup_grid(_w = 10, _h = 8) {
	
    if (variable_global_exists("mansion_map") && global.mansion_map != noone) {
        ds_grid_destroy(global.mansion_map);
    }
    global.mansion_map = ds_grid_create(_w, _h);
	
    ds_grid_set_region(global.mansion_map, 0, 0, _w - 1, _h - 1, -1);
}


/// Create an obj_chamber at a grid cell and register it in the map (honouring size).
/// NOTE: relies on a real chamber sprite existing for <_type>/<size> and on
/// scr_get_chamber_tags() being available. Use valid types
/// from datafiles/chamber_types/ (e.g. "boudoir", "bar").
function test_place_chamber(_type, _gx, _gy, _size = ROOM_SIZE.SMALL) {
    var _inst = instance_create_layer(0, 0, "Instances", obj_chamber,
        { chamber_type: _type, chamber_size: _size, grid_x: _gx, grid_y: _gy });

    var _d = global.size_dims[_size];
    for (var _x = 0; _x < _d.w; _x++)
        for (var _y = 0; _y < _d.h; _y++)
            ds_grid_set(global.mansion_map, _gx + _x, _gy + _y, _inst);

    return _inst;
}

// ---------------------------------------------------------------------------
// Clients / Minions (spec-only objects — will error until they exist)
// ---------------------------------------------------------------------------

/// Build a guest/client instance with explicit fields (no RNG).
function test_make_client(_name = "Guest", _tags = [], _backstory = "", _freq = 1.0) {
    var _c = create(0, 0, obj_client);
    _c.name            = _name;
    _c.tags            = array_concat(_tags, []); // Need to concat an empty array to create a new one.
    _c.backstory       = _backstory;
    _c.visit_frequency = _freq;
    _c.converted       = false;
    return _c;
}

/// Build a minion instance with explicit fields (no RNG).
function test_make_minion(_tags = [], _quirk = "", _chamber = no, _is_friend = false) {
    var _m = create(0, 0, obj_minion);
    _m.tags            = array_concat(_tags, []); // workaround for lack of array clone
    _m.quirk           = _quirk;
    _m.current_chamber = _chamber;
    _m.is_friend       = _is_friend;
    return _m;
}

// ---------------------------------------------------------------------------
// Teardown
// ---------------------------------------------------------------------------

/// Tear down all chamber/minion/client instances created during a test.
function test_cleanup_instances() {
    with (obj_chamber) instance_destroy();
    if (object_exists(obj_minion))  with (obj_minion)  instance_destroy();
    if (object_exists(obj_client))  with (obj_client)  instance_destroy();
}

/// Reset the grid AND clear instances. Use in afterEach for full isolation.
function test_teardown() {
    test_cleanup_instances();
    global.mansion_map = noone;
}
