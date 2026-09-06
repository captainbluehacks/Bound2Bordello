/// @description Suite B: Grid / adjacency / floor geometry.

suite(function () {
    section("Grid Geometry", function () {
        beforeEach(function () { test_setup_grid(); });
        afterEach (function () { test_teardown(); });

        // -------------------------------------------------------------------
        // B1. Adjacency — scr_get_adjacent_chambers
        // -------------------------------------------------------------------
        each("adjacency: {0} next to {1}", function (_subject_type, _neighbour_type) {
            var _s = test_place_chamber(_subject_type, 4, 4);   // 1x1 at (4,4)
            var _n = test_place_chamber(_neighbour_type, 5, 4); // 1x1 to the right

            var _adj = scr_get_adjacent_chambers(_s);
            expect(array_length(_adj)).toBe(1);
            expect(_adj[0]).toBe(_n);
        }, [
            ["boudoir", "glory_hole"],
            ["bar",     "boudoir"]
        ]);

        it("a room with nothing around it has no neighbours", function () {
            var _s = test_place_chamber("boudoir", 4, 4);
            var _adj = scr_get_adjacent_chambers(_s);
            expect(array_length(_adj)).toBe(0);
        });

        it("multi-cell neighbour is deduped to a single entry", function () {
            // 2x1 (medium) touching a 1x1 on its right edge.
            var _s = test_place_chamber("bar", 4, 4, ROOM_SIZE.MEDIUM);   // occupies (4,4),(5,4)
            var _n = test_place_chamber("boudoir", 6, 4);                 // touches at x=6

            var _adj = scr_get_adjacent_chambers(_s);
            expect(array_length(_adj)).toBe(1);   // not 2 (dedup via ds_set)
            expect(_adj[0]).toBe(_n);
        });

        it("corner placement skips out-of-bounds cells without crashing", function () {
            var _s = test_place_chamber("boudoir", 0, 0); // top-left corner
            var _adj = scr_get_adjacent_chambers(_s);     // should be empty, no crash
            expect(array_length(_adj)).toBe(0);
            ds_list_destroy(_adj);
        });

        // -------------------------------------------------------------------
        // B2. Directional adjacency — scr_is_in_direction (exhaustive table)
        // -------------------------------------------------------------------
        each("direction: subject {0}x{1}, neighbour at offset, dir={2} => {3}",
            function (_sw, _sh, _nx, _ny, _dir, _expected) {
                var _s = test_place_chamber("boudoir", 4, 4); // 1x1 subject at (4,4)
                var _n = test_place_chamber("glory_hole", _nx, _ny);

                expect(scr_is_in_direction(_s, _n, _dir)).toBe(_expected);
            }, [
            // neighbour strictly above (y-1), overlapping x => up true
            [1, 1, 4, 3, "up",    true],
            // diagonal only => false for all directions
            [1, 1, 5, 3, "up",    false],
            [1, 1, 5, 3, "right", false],
            // gap of one cell (y-2) => not touching
            [1, 1, 4, 2, "up",    false],
            // directly below
            [1, 1, 4, 5, "down",  true],
            // directly left / right
            [1, 1, 3, 4, "left",  true],
            [1, 1, 5, 4, "right", true],

            // 2x1 subject above a 2x1 neighbour: full-width overlap => down true
            [2, 1, 4, 5, "down",  true]
        ]);

        it("unknown direction returns false (and does not crash)", function () {
            var _s = test_place_chamber("boudoir", 4, 4);
            var _n = test_place_chamber("glory_hole", 5, 4);
            expect(scr_is_in_direction(_s, _n, "diagonal")).toBe(false);
        });

        // -------------------------------------------------------------------
        // B3. Floor mapping — scr_grid_y_to_floor (table)
        // -------------------------------------------------------------------
        each("floor: y={0} => [{1},{2}]", function (_y, _min, _max) {
            var _rows = scr_grid_y_to_floor(_y);
            expect(_rows[0]).toBe(_min);
            expect(_rows[1]).toBe(_max);
        }, [
            [0, 0, 1],   // Attic
            [1, 0, 1],
            [2, 2, 3],   // First
            [3, 2, 3],
            [4, 4, 5],   // Ground
            [5, 4, 5],
            [6, 6, 7],   // Basement
            [7, 6, 7]
        ]);

        it("out-of-range y returns noone (current behaviour)", function () {
            expect(scr_grid_y_to_floor(8)).toBe(noone);
            expect(scr_grid_y_to_floor(-1)).toBe(noone);
        });

        // -------------------------------------------------------------------
        // B5. Floor tag counting — scr_count_tag_on_floor
        // -------------------------------------------------------------------
        it("counts unique chambers carrying the tag on the same floor only", function () {
            // Ground floor = rows 4-5. Place two 'tips'-tagged rooms + one other.
            test_place_chamber("boudoir",    2, 4); // tags: sex, tips
            test_place_chamber("glory_hole", 3, 4); // tags: tips, degradation
            test_place_chamber("massage_parlour", 4, 4); // tags: flirt (no 'tips')

            var _probe = test_place_chamber("counting_room", 5, 4); // ground floor probe
            expect(scr_count_tag_on_floor(_probe, "tips", 10)).toBe(2);
        });

        it("respects the max cap", function () {
            test_place_chamber("boudoir",    2, 4);
            test_place_chamber("glory_hole", 3, 4);
            var _probe = test_place_chamber("counting_room", 5, 4);
            expect(scr_count_tag_on_floor(_probe, "tips", 1)).toBe(1);
        });

        it("ignores chambers on other floors", function () {
            // 'tips' room on the attic (row 0), probe on ground (row 4).
            test_place_chamber("boudoir", 2, 0);
            var _probe = test_place_chamber("counting_room", 5, 4);
            expect(scr_count_tag_on_floor(_probe, "tips", 10)).toBe(0);
        });

        // -------------------------------------------------------------------
        // B4. Effective tags — scr_get_effective_tags (spec-only for upgrades)
        // -------------------------------------------------------------------
        it("returns base type tags when no upgrade is installed", function () {
            var _c = test_place_chamber("boudoir", 2, 4);
            var _tags = scr_get_effective_tags(_c);
            expect(array_length(_tags)).toBe(2); // sex, tips
            expect(_tags).toContain("sex");
            expect(_tags).toContain("tips");
        });

        skip("upgrade tags_added are unioned without duplicates (spec-only: scr_get_upgrade returns [])", function () {
            // TODO(Phase 1): stub a real upgrade lookup, then assert base + added, no dups.
        });
    });
});

