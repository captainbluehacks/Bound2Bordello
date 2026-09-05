suite("Grid / Adjacency / Floor Geometry", function () {
    
    section("Adjacency (scr_get_adjacent_chambers)", function () {
        // Test 1x1 next to 1x1 -> exactly one neighbour
        // We use a small grid and place rooms. 
        // Note: We must ensure the grid is populated such that we can test boundaries.
        
        test_setup_grid(5, 5);
        
        section("Boundary Check", function() {
            var _inst = test_place_chamber("some_type", 2, 2, ROOM_SIZE.SMALL);
            // Testing that a room at the edge doesn't crash and finds no neighbors outside bounds
            var _neighbors = scr_get_adjacent_chambers(2, 2);
            expect(_neighbors).toHaveLength(0);
        });

        section("Internal Adjacency", function() {
            // Place a room at 1,1 and another at 1,2 (if possible)
            // This tests the ring scan logic.
            test_setup_grid(5, 5);
            var _inst1 = test_place_chamber("type_a", 1, 1, ROOM_SIZE.SMALL);
            var _inst2 = test_place_chamber("type_b", 1, 2, ROOM_SIZE.SMALL);
            
            // The ring scan should find the neighbor if it's adjacent
            var _neighbors = scr_get_adjacent_chambers(1, 1);
            // We check if it finds the instance at 1,2
            // Note: Depending on your implementation of scr_get_adjacent_chambers, 
            // you might need to adjust how you assert.
            expect(_neighbors).toContain(_inst2);
        });
    });

    section("Directional Adjacency (scr_is_in_direction)", function () {
        test_setup_grid(5, 5);
        
        // Test: A room at 1,1 should NOT see a room at 2,2 as 'up', 'down', 'left', or 'right'
        var _inst_diag = test_place_chamber("type_a", 2, 2, ROOM_IS_SMALL); // Using small for safety
        var _target = test_place_chamber("type_b", 1, 1, ROOM_SIZE.SMALL);
        
        expect(scr_is_in_direction(_target, "up")).toBeFalse();
        expect(scr_is_in_direction(_target, "down")).toBeFalse();
        expect(scr_is_in_direction(_target, "left")).toBeFalse();
        expect(scr_is_in_direction(_target, "right")).toBeFalse();

        // Test: A room at 1,1 SHOULD see a room at 2,1 as 'right' (if logic allows)
        var _inst_right = test_place_chamber("type_c", 2, 1, ROOM_SIZE.SMALL);
        expect(scr_is_in_direction(_target, "right")).toBeTrue();
    });

    section("Floor Mapping (scr_grid_y_to_floor)", function () {
        // This is a pure mapping test. We check the lookup table logic.
        // Testing the boundary/fallback behavior.
        
        expect(scr_grid_y_to_floor(0)).toBe("Attic");
        expect(scr_grid_y_to_floor(1)).toBe("Attic");
        expect(scr_grid_y_to_floor(2)).toBe("First");
        expect(scr_grid_y_to_floor(7)).toBe("Basement");
        expect(scr_grid_y_to_floor(8)).toBe(noone); // Out of range fallback
    });

    section("Floor Tag Counting (scr_count_tag_on_floor)", function () {
        test_setup_grid(5, 5);
        // Ensure we don't count across floors
        var _inst_ground = test_place_chamber("type_a", 4, 4, ROOM_SIZE.SMALL);
        _inst_ground.tags = ["some_tag"];
        
        expect(scr_count_tag_on_floor(4, "some_tag")).toBe(1);
        expect(scr_count_tag_on_floor(2, "some_tag")).toBe(0); // Different floor
    });

}));
