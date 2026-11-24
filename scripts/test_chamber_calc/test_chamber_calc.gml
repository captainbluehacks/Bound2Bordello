/// @description Suite A: Chamber contribution engine — condition types, upgrade
/// loader/contribution, and the nightly-sum aura pass.
/// Covers P0 tasks 2–5 in PLAYABLE_TURNS_TASKS.md (count_adjacent_tag, upgrade
/// loader + scr_get_upgrade, aura pass, minion_has_tag / upgrade_present).

/// Test-local helper: find a chamber's result entry inside a nightly summary.
function _test_find_result(_summary, _chamber) {
    for (var i = 0; i < array_length(_summary.active_rooms); i++) {
        if (_summary.active_rooms[i].chamber == _chamber) return _summary.active_rooms[i].result;
    }
    return undefined;
}

suite(function () {
    section("count_adjacent_tag condition (task 2)", function () {
        beforeEach(function () { test_setup_grid(); });
        afterEach (function () { test_teardown(); });

        it("counts unique adjacent chambers carrying the tag", function () {
            test_place_chamber("boudoir",    3, 4); // tags: sex, tips
            test_place_chamber("glory_hole", 5, 4); // tags: tips, degradation
            var _probe = test_place_chamber("counting_room", 4, 4);

            expect(scr_eval_condition(_probe, { type: "count_adjacent_tag", tag: "tips" })).toBe(2);
        });

        it("ignores non-adjacent chambers on the same floor", function () {
            test_place_chamber("boudoir", 1, 4); // 'tips', but not adjacent to probe at (5,4)
            var _probe = test_place_chamber("counting_room", 5, 4);

            expect(scr_eval_condition(_probe, { type: "count_adjacent_tag", tag: "tips" })).toBe(0);
        });

        it("ignores adjacent chambers that lack the tag", function () {
            test_place_chamber("massage_parlour", 3, 4); // tags: flirt only
            var _probe = test_place_chamber("counting_room", 4, 4);

            expect(scr_eval_condition(_probe, { type: "count_adjacent_tag", tag: "tips" })).toBe(0);
        });

        it("respects the optional max cap", function () {
            test_place_chamber("boudoir",    3, 4);
            test_place_chamber("glory_hole", 5, 4);
            var _probe = test_place_chamber("counting_room", 4, 4);

            expect(scr_eval_condition(_probe, { type: "count_adjacent_tag", tag: "tips", max: 1 })).toBe(1);
        });

        it("counts upgrade-added tags (effective tags)", function () {
            var _c = test_place_chamber("boudoir", 3, 4); // base tags: sex, tips — no degradation
            _c.upgrade_id = "whip_set";                    // adds: degradation
            var _probe = test_place_chamber("counting_room", 4, 4);

            expect(scr_eval_condition(_probe, { type: "count_adjacent_tag", tag: "degradation" })).toBe(1);
        });

        it("dedupes a multi-cell neighbour to a single count", function () {
            var _n = test_place_chamber("bar", 2, 4, ROOM_SIZE.MEDIUM); // (2,4)+(3,4), tags include tips
            var _probe = test_place_chamber("counting_room", 4, 4);

            expect(scr_eval_condition(_probe, { type: "count_adjacent_tag", tag: "tips" })).toBe(1);
        });

        it("feeds effects_per_match through a real chamber (Counting Room → Value)", function () {
            test_place_chamber("boudoir",    3, 4);
            test_place_chamber("glory_hole", 5, 4);
            var _probe = test_place_chamber("counting_room", 4, 4); // requires: none → active

            var _result = scr_calculate_chamber(_probe);
            expect(_result.active).toBe(true);
            expect(_result.total.value).toBe(2);
        });
    });

    section("minion_has_tag condition (task 5)", function () {
        beforeEach(function () { test_setup_grid(); });
        afterEach (function () { test_teardown(); });

        it("true when an assigned minion carries the tag", function () {
            var _c = test_place_chamber("boudoir", 4, 4);
            array_push(_c.minions, test_make_minion(["devoted"]));

            expect(scr_eval_condition(_c, { type: "minion_has_tag", tag: "devoted" })).toBe(true);
        });

        it("false when the assigned minion lacks the tag", function () {
            var _c = test_place_chamber("boudoir", 4, 4);
            array_push(_c.minions, test_make_minion(["succubus"]));

            expect(scr_eval_condition(_c, { type: "minion_has_tag", tag: "devoted" })).toBe(false);
        });

        it("false when no minion is assigned", function () {
            var _c = test_place_chamber("boudoir", 4, 4);

            expect(scr_eval_condition(_c, { type: "minion_has_tag", tag: "devoted" })).toBe(false);
        });

        it("true if ANY occupied slot carries the tag (multi-slot room)", function () {
            var _c = test_place_chamber("lobby", 4, 4, ROOM_SIZE.LARGE);
            array_push(_c.minions, test_make_minion(["succubus"]));
            array_push(_c.minions, test_make_minion(["devoted"]));

            expect(scr_eval_condition(_c, { type: "minion_has_tag", tag: "devoted" })).toBe(true);
        });

        it("skips empty (noone) slots", function () {
            var _c = test_place_chamber("lobby", 4, 4, ROOM_SIZE.LARGE);
            array_push(_c.minions, noone);
            array_push(_c.minions, test_make_minion(["devoted"]));

            expect(scr_eval_condition(_c, { type: "minion_has_tag", tag: "devoted" })).toBe(true);
        });
    });

    section("upgrade_present condition (task 5)", function () {
        beforeEach(function () { test_setup_grid(); });
        afterEach (function () { test_teardown(); });

        it("true when the named upgrade is installed", function () {
            var _c = test_place_chamber("boudoir", 4, 4);
            _c.upgrade_id = "silk_sheets";

            expect(scr_eval_condition(_c, { type: "upgrade_present", upgrade_id: "silk_sheets" })).toBe(true);
        });

        it("false when a different upgrade is installed", function () {
            var _c = test_place_chamber("boudoir", 4, 4);
            _c.upgrade_id = "tip_jar";

            expect(scr_eval_condition(_c, { type: "upgrade_present", upgrade_id: "silk_sheets" })).toBe(false);
        });

        it("false when no upgrade is installed", function () {
            var _c = test_place_chamber("boudoir", 4, 4); // Create sets upgrade_id = noone

            expect(scr_eval_condition(_c, { type: "upgrade_present", upgrade_id: "silk_sheets" })).toBe(false);
        });
    });

    section("Upgrade loader + scr_get_upgrade (task 3)", function () {
        it("returns the loaded definition for a known id", function () {
            var _upg = scr_get_upgrade("whip_set");

            expect(_upg.display_name).toBe("Whip & Chain Set");
            expect(array_contains(_upg.compatible_types, "boudoir")).toBe(true);
            expect(_upg.tags_added).toContain("degradation");
        });

        it("uses whitelisted resource keys in effects (no *_mana leftovers)", function () {
            var _silk = scr_get_upgrade("silk_sheets");
            var _whip = scr_get_upgrade("whip_set");

            expect(_silk.effects.lust).toBe(2);
            expect(struct_exists(_silk.effects, "lust_mana")).never().toBe(true);
            expect(_whip.effects.humiliation).toBe(2);
            expect(struct_exists(_whip.effects, "humiliation_mana")).never().toBe(true);
        });

        it("returns undefined for an unknown id", function () {
            expect(scr_get_upgrade("does_not_exist")).toBe(undefined);
        });
    });

    section("Upgrade contribution in chamber calc (task 3)", function () {
        beforeEach(function () { test_setup_grid(); });
        afterEach (function () { test_teardown(); });

        it("compatible upgrade adds its effects and a breakdown line", function () {
            var _c = test_place_chamber("boudoir", 4, 4);
            array_push(_c.minions, test_make_minion(["devoted"]));
            array_push(_c.clients, test_make_client());
            _c.upgrade_id = "silk_sheets"; // +2 lust

            var _result = scr_calculate_chamber(_c);
            expect(_result.total.lust).toBe(7);  // base 5 + upgrade 2
            expect(_result.total.cash).toBe(2);

            var _found = false;
            for (var i = 0; i < array_length(_result.lines); i++) {
                if (_result.lines[i].label == "upgrade_silk_sheets") _found = true;
            }
            expect(_found).toBe(true);
        });

        it("incompatible upgrade is not applied", function () {
            var _c = test_place_chamber("glory_hole", 4, 4); // silk_sheets only fits boudoir
            array_push(_c.minions, test_make_minion(["devoted"]));
            array_push(_c.clients, test_make_client());
            _c.upgrade_id = "silk_sheets";

            var _result = scr_calculate_chamber(_c);
            expect(_result.total.cash).toBe(4); // base only

            var _found = false;
            for (var i = 0; i < array_length(_result.lines); i++) {
                if (_result.lines[i].label == "upgrade_silk_sheets") _found = true;
            }
            expect(_found).never().toBe(true);
        });
    });

    section("Aura pass in nightly sum (task 4)", function () {
        beforeEach(function () { test_setup_grid(); });
        afterEach (function () { test_teardown(); });

        it("applies the adder's aura to each unique adjacent chamber and the grand total", function () {
            var _laundry = test_place_chamber("laundry", 4, 4); // aura: stock+1, influence+1
            var _left   = test_place_chamber("boudoir",    3, 4);
            array_push(_left.minions, test_make_minion(["devoted"]));
            array_push(_left.clients, test_make_client());
            var _right  = test_place_chamber("glory_hole", 5, 4);
            array_push(_right.minions, test_make_minion(["devoted"]));
            array_push(_right.clients, test_make_client());

            var _summary = scr_calculate_night_earnings();

            // Grand total: boudoir {lust 5, cash 2} + glory_hole {cash 4, humiliation 1} + 2× aura.
            expect(_summary.earnings.lust).toBe(5);
            expect(_summary.earnings.cash).toBe(6);
            expect(_summary.earnings.humiliation).toBe(1);
            expect(_summary.earnings.stock).toBe(2);
            expect(_summary.earnings.influence).toBe(2);

            // Each neighbour's own total includes the aura exactly once.
            var _left_res = _test_find_result(_summary, _left);
            expect(_left_res.total.lust).toBe(5);
            expect(_left_res.total.stock).toBe(1);
            expect(_left_res.total.influence).toBe(1);

            var _right_res = _test_find_result(_summary, _right);
            expect(_right_res.total.cash).toBe(4);
            expect(_right_res.total.stock).toBe(1);
            expect(_right_res.total.influence).toBe(1);

            // The adder itself gets nothing from its own aura.
            var _laundry_res = _test_find_result(_summary, _laundry);
            expect(struct_exists(_laundry_res.total, "stock")).never().toBe(true);
            expect(struct_exists(_laundry_res.total, "influence")).never().toBe(true);

            // A breakdown line is recorded on the target chamber.
            var _aura_line = false;
            for (var i = 0; i < array_length(_left_res.lines); i++) {
                if (_left_res.lines[i].label == "aura_laundry") _aura_line = true;
            }
            expect(_aura_line).toBe(true);
        });

        it("two adjacent adders both apply to the same target (order-independent)", function () {
            var _target = test_place_chamber("boudoir", 4, 4);
            array_push(_target.minions, test_make_minion(["devoted"]));
            array_push(_target.clients, test_make_client());
            test_place_chamber("laundry", 3, 4); // aura: stock+1, influence+1
            test_place_chamber("shower", 5, 4);  // aura: lust+1, influence+1

            var _summary = scr_calculate_night_earnings();

            expect(_summary.earnings.stock).toBe(1);
            expect(_summary.earnings.lust).toBe(6);    // boudoir base 5 + shower aura 1
            expect(_summary.earnings.influence).toBe(2);

            var _res = _test_find_result(_summary, _target);
            expect(_res.total.stock).toBe(1);
            expect(_res.total.lust).toBe(6);
            expect(_res.total.influence).toBe(2);
        });

        it("applies aura even when the target chamber is inactive", function () {
            test_place_chamber("laundry", 4, 4);
            var _boudoir = test_place_chamber("boudoir", 3, 4); // no minion → inactive

            var _summary = scr_calculate_night_earnings();

            expect(_summary.earnings.stock).toBe(1);
            expect(_summary.earnings.influence).toBe(1);

            var _found_inactive = false;
            for (var i = 0; i < array_length(_summary.inactive_rooms); i++) {
                if (_summary.inactive_rooms[i].chamber == _boudoir) _found_inactive = true;
            }
            expect(_found_inactive).toBe(true);
        });

        it("applies aura even when the adder itself is inactive", function () {
            test_place_chamber("laundry", 4, 4); // no minion assigned
            var _target = test_place_chamber("boudoir", 3, 4);
            array_push(_target.minions, test_make_minion(["devoted"]));
            array_push(_target.clients, test_make_client());

            // Force the laundry's type def to require a minion (restored before asserting).
            var _def = scr_get_chamber_type("laundry");
            var _orig_requires = _def.requires;
            _def.requires = { minion: true };

            var _summary = scr_calculate_night_earnings();
            _def.requires = _orig_requires; // restore so a failure can't leak state

            expect(_summary.earnings.stock).toBe(1);
            expect(_summary.earnings.influence).toBe(1);
        });

        it("applies aura to a multi-cell neighbour exactly once", function () {
            test_place_chamber("laundry", 4, 4);
            var _bar = test_place_chamber("bar", 5, 4, ROOM_SIZE.MEDIUM); // (5,4)+(6,4) both in laundry's ring
            array_push(_bar.minions, test_make_minion(["devoted"]));
            array_push(_bar.clients, test_make_client());

            var _summary = scr_calculate_night_earnings();

            expect(_summary.earnings.stock).toBe(1); // once, not twice
            var _res = _test_find_result(_summary, _bar);
            expect(_res.total.stock).toBe(1);
        });
    });
});
