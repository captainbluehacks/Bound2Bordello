suite("Grid / Adjacency / Floor Geometry", function () {
    
    section("Adjacency (scr_get_adjacent_chambers)", function () {
        test_setup_grid(5, 5);
        
        section("Boundary Check", function() {
            var _inst = test_place_chamber("some_type", 2, 2, ROOM_SIZE.SMALL);
            var _neighbors = scr_get_adjacent_chambers(_inst);
            expect(_neighbors).toHaveLength(0);
        });

        section("Internal Adjacency", function() {
            test_setup_grid(5, 5);
            var _inst1 = test_place_chamber("type_a", 1, 1, ROOM_SIZE.SMALL);
            var _inst2 = test_place_chamber("type_b", 1, 2, ROOM_SIZE.SMALL);
            
            // The ring scan should find the neighbor if it's adjacent
            var _neighbors = scr_get_adjacent_chambers(_inst1);
            expect(_neighbors).toContain(_inst2);
        });
    });

    section("Directional Adjacency (scr_is_in_direction)", function () {
        test_setup_grid(5, 5);
        
        var _target = test_place_chamber("type_b", 1, 1, ROOM_SIZE.SMALL);
        var _inst_diag = test_place_chamber("type_a", 2, 2, ROOM_SIZE.SMALL);
        
        expect(scr_is_in_direction(_target, "up")).toBeFalse();
        expect(scr_is_in_direction(_target, "down")).toBeFalse();
        expect(scr_is_in_direction(_target, "left")).toBeFalse();
        expect(scr_is_in_direction(_target, "right")).toBeFalse();

        var _inst_right = test_place_chamber("type_c", 2, 1, ROOM_SIZE.SMALL);
        expect(scr_is_in_direction(_target, "right")).toBeTrue();
    });

    section("Floor Mapping (scr_grid_y_to_floor)", function () {
        test_setup_grid(5, 5);
        expect(scr_grid_y_to_floor(0)).toBe("Attic");
        expect(scr_grid_y_to_floor(2)).toBe("First");
        expect(scr_grid_y_to_floor(8)).toBe(noone); 
    });

    section("Floor Tag Counting (scr_count_tag_on_floor)", function () {
        test_setup_grid(5, 5);
        var _inst_ground = test_place_chamber("type_a", 4, 4, ROOM_SIZE.SMALL);
        _inst_grim = _inst_ground; // Reference for testing
        _inst_ground.tags = ["some_tag"];
        
        expect(scr_count_tag_on_floor(4, "some_tag")).toBe(1);
        expect(scr_count_tag_on_floor(2, "some_tag")).toBe(0); 
    });

    // Final cleanup for the suite itself
    afterAll(function() {
        test_cleanup_instances();
    });
    
    // Ensure every section cleans up to prevent leakage
    beforeEach(function() {
        test_cleanup_instances();
        test_setup_grid(5, 5);
    });

}));
