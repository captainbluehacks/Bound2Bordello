# Bound to the Bordello — Testing Plan

A testing strategy for **Bound to the Bordello** built on the [GameMaker's Testing Library (GMTL)](https://github.com/DAndrewBox/GM-Testing-Library) v1.2, which is already vendored into this project under `scripts/GMTL_*`.

This plan is written against the *current* code in the repo (`scr_chamber_calc.gml`, `scr_mansion_rooms.gml`, `scr_chamber_types.gml`) and the two technical specs (`CHAMBER_SYSTEM_SPEC.md`, `MINION_STATE_SPEC.md`). Where the spec describes behaviour that isn't implemented yet, it is flagged as **spec-only** so you know which tests are forward-looking.

---

## 1. Goals & Principles

The game's risk lives in its **data-driven simulation logic**, not its rendering:

- The Chamber Contribution Engine (JSON → nightly resource totals).
- The Minion State Machine (tags, progression tracks, terminals).
- Grid / adjacency / floor geometry on the `mansion_map` `ds_grid`.
- Resource economy math and cost/affordability checks.

These are almost all **pure functions** that read a grid + JSON and return numbers/maps. That makes them ideal for fast, deterministic unit tests — the core reason to adopt GMTL here.

Principles:

1. **Test behaviour, not implementation.** Assert on returned totals, tag arrays, and instance state — not on internal call order (except where an event *must* fire).
2. **Deterministic first.** The engine is deterministic except for `random()` in flat-tag application and blueprint selection. Isolate those two sources of non-determinism so tests are repeatable.
3. **One suite per system, one section per function/behaviour.** Keep suites small enough to read the failure output at a glance.
4. **Data-driven where it pays off.** Use `each()` for table cases (floor mapping, condition types, terminal actions) instead of copy-pasted tests.
5. **Coverage as a floor, not a target.** Enable GMTL's function coverage and aim to cover every *named* engine function; don't chase 100% on UI/presentation code.

---

## 2. What to Test (and what to skip)

| Layer | Examples | Strategy |
|-------|----------|----------|
| **Pure math / data** | `scr_chamber_sum_resources`, floor mapping, condition evaluation, tag counting | Heavy unit coverage — highest value, cheapest. |
| **Grid geometry** | `scr_get_adjacent_chambers`, `scr_is_in_direction` (all sizes) | Unit tests with hand-built grids; use `each()` for size combos. |
| **Engine entry points** | `scr_calculate_chamber`, `scr_calculate_night_earnings`, `scr_process_minion_states` | Integration-style: build a small grid, run the pass, assert totals/state. |
| **Data loading / validation** | `scr_load_chamber_types`, JSON schema integrity | Contract tests over the real `datafiles/`. |
| **Objects & events** | `obj_chamber` create, UI buttons, camera | Light: use GMTL `create()` + `simulateEvent`/input for a few key flows. |
| **Presentation / feel** | lerp transitions, paper-doll animation, audio | **Skip automated tests.** Manual playtest only — not worth the brittleness. |

Rule of thumb: if a function is pure and returns data → test it hard. If it draws pixels or plays sound → don't.

---

## 3. Test Infrastructure & Conventions

### 3.1 File layout

Keep tests out of the way but discoverable. Suggested structure (one suite per file, matching GMTL's "single suite per script" recommendation):

```
scripts/
    test/                          # your test suites (folder name does NOT start with GMTL_)
        test_chamber_calc.gml      #   suite: Chamber Contribution Engine
        test_mansion_grid.gml      #   suite: Grid / adjacency / floor geometry
        test_minion_state.gml      #   suite: Minion State Machine
        test_data_integrity.gml    #   suite: JSON data contract tests
        test_ui_smoke.gml          #   suite: object/event smoke tests (optional)
```

> Note on coverage: GMTL scans `scripts/` and **excludes** folders starting with `GMTL_`. Your `test/` folder is fine — but remember the *functions under test* must be named functions in non-`GMTL_` scripts to appear in the report (they already are).

### 3.2 Shared fixtures / helpers

Create a small helper script (e.g. `scripts/test/test_helpers.gml`) with reusable builders so suites stay DRY:

```gml
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

/// Tear down all chamber/minion instances created during a test.
function test_cleanup_instances() {
    with (obj_chamber) instance_destroy();
    with (obj_minion)  instance_destroy();
}
```

Use `beforeEach` / `afterEach` to reset state so tests don't leak into each other:

```gml
suite(function () {
    section("Chamber Contribution Engine", function () {
        beforeEach(function () { test_setup_grid(); });
        afterEach(function  () { test_cleanup_instances(); });
        // ...tests...
    });
});
```

> **Important GMTL gotcha:** variables declared inside `before*`/`after*` hooks are *not* visible in the tests. Share state via globals or a struct (e.g. stash created instance ids on a global test-state struct) if you need to reference them later.

### 3.3 Determinism controls

Two sources of randomness must be tamed:

1. **Flat-tag `chance`** (`scr_apply_flat_tags` uses `random(1.0)`). For deterministic tests, either (a) test with `chance = 1.0` / `chance = 0.0`, or (b) seed the RNG at the start of a section:
   ```gml
   beforeAll(function () { randomize(); }); // or set a fixed seed if you add one
   ```
   For probabilistic tags, assert *statistical* properties over many iterations rather than exact outcomes.

2. **Blueprint selection** (`define_floors` uses `irandom`). Don't unit-test the random pick; test `validate_template` and the layout→grid population with a fixed blueprint array instead.

### 3.4 Running & gating tests

- GMTL runs suites automatically at game start (after `gmtl_wait_frames_before_start`, default 10 frames) via `GMTL_init`. Results print to the debug console.
- **Recommended:** add a dedicated *test room* / test build so you can run the full suite without booting into normal gameplay. Set `gmtl_run_at_start = true` for that build and keep it `false` in your play builds (see `GMTL_definitions.gml`).
- **Coverage:** flip `gmtl_show_coverage = true` in `scripts/GMTL_definitions/GMTL_definitions.gml` to get the function-level report after each run.
- **CI note:** GMTL is an in-engine runner, so there's no headless CLI out of the box. If you want CI gating later, build a small "test harness" room that writes pass/fail + coverage to a file (or `show_debug_message` → captured log) and exits with a non-zero code on failure. Treat this as a Phase 4 nicety, not a blocker.

---

## 4. Test Suites — Detailed Breakdown

### Suite A: Chamber Contribution Engine (`test_chamber_calc.gml`)

The highest-value suite. Target functions: `scr_calculate_chamber`, `scr_chamber_check_prerequisites`, `scr_chamber_apply_base/bonuses/upgrades`, `scr_chamber_sum_resources`, `scr_eval_condition`, and the nightly sum.

**A1. Prerequisite gate (`scr_chamber_check_prerequisites`)**
- Room with `requires.minion = true` + no minion → `{ active: false, reason: "No minion assigned" }`.
- Room with `requires.client = true` + empty client array → inactive, `"No client present"`.
- Passive room (`requires.minion = false`) with no minion but a client → **active**.
- Type def missing the `requires` key entirely → active (the `struct_exists` guard).
- Both satisfied → `{ active: true }`.

**A2. Base output (`scr_chamber_apply_base`)**
- A type with `base = { lust_mana: 5, value: 5 }` produces exactly those totals and one breakdown line labelled `"Base"`.
- Type with no `base` key → contributes nothing (guard path), no crash.

**A3. Bonus rules (`scr_chamber_apply_bonuses`)**
- Boolean condition met → flat `effects` added, one line per triggered rule.
- Condition not met → skipped, no line.
- **Scaled rule:** `effects_per_match = { cash: 5 }` with a count condition returning N → total adds `cash: 5*N`. Verify the multiplication path (this is where off-by-one bugs hide).
- Multiple bonuses in one type → all independent lines accumulate correctly.

**A4. Upgrade contribution (`scr_chamber_apply_upgrades`)**
- Compatible upgrade installed → its `effects` added, line labelled `"upgrade_<id>"`.
- Incompatible upgrade (type not in `compatible_types`, no `"*"`) → **not** applied.
- Wildcard `"*"` upgrade → applies to any room.
- No upgrade (`""` / `noone`) → early return, nothing added.

> ⚠️ **Current-code caveat:** `scr_get_upgrade()` currently returns `[]`. Until the real upgrade loader exists, A4 tests will exercise the "undefined/empty" path only. Either stub a lookup table in your test fixture or mark these as **spec-only** until upgrades are wired up.

**A5. Resource summation (`scr_chamber_sum_resources`)**
- Adding into an empty total creates keys at 0 + value.
- Adding the same resource twice accumulates (idempotent key handling).
- Mixed resources sum independently.

**A6. Condition evaluation (`scr_eval_condition`) — use `each()`**

| condition.type | Fixture | Expected |
|---|---|---|
| `adjacent_room_type` | matching neighbour present / absent | true / false |
| `adjacent_room_type` + `direction` | neighbour only on the *wrong* side | false (see Suite B) |
| `count_tag_on_floor` | N tagged rooms on floor, cap `max` | min(N, max) |
| `minion_assigned` | minion present / absent | true / false |
| `floor_is` | chamber on that floor / not | true / false |
| unknown type | `{ type: "bogus" }` | returns `false` (and logs) — assert no crash |

**A7. Nightly sum (`scr_calculate_night_earnings`)**
- Empty grid → empty earnings, no active/inactive rooms.
- Grid with a mix of active + inactive chambers → grand total equals the sum of only the active ones; `active_rooms[]` / `inactive_rooms[]` partition correctly (with reasons).
- **Multi-cell dedup:** place one 2×2 room and confirm it is counted exactly once (the `ds_map` `_seen` guard). This is a classic double-count bug — test it explicitly.

**A8. Aura pass (spec-only)**
The spec describes an aura pass in the nightly sum, but the current `scr_calculate_night_earnings()` does **not** implement it yet. Write these as forward-looking tests once implemented:
- Adder room's `aura` applied to each unique adjacent chamber exactly once.
- Aura does not apply to the adder itself.
- Two adjacent adders both buff the same target (additive, order-independent).

---

### Suite B: Grid / Adjacency / Floor Geometry (`test_mansion_grid.gml`)

Target functions in `scr_mansion_rooms.gml`: `scr_get_adjacent_chambers`, `scr_check_adjacent`, `scr_is_in_direction`, `scr_count_tag_on_floor`, `scr_get_effective_tags`, `scr_get_floor_row_range`.

**B1. Adjacency (`scr_get_adjacent_chambers`)** — use `each()` over size combinations:
- 1×1 next to 1×1 → exactly one neighbour.
- 2×1 / 2×2 rooms touching a 1×1 → correct unique set (multi-cell neighbours deduped via the ring scan).
- Corner/edge placement → out-of-bounds cells skipped, no crash.
- A room with nothing around it → empty list.

**B2. Directional adjacency (`scr_is_in_direction`)** — exhaustive `each()` table:
For each direction (`up`, `down`, `left`, `right`) and size pair (1×1/1×1, 2×1/1×1, 2×2/2×2):
- Neighbour strictly on that side with overlap → **true**.
- Diagonal-only contact → **false** for all directions.
- Non-touching (gap of one cell) → **false**.
- A 2×1 directly above a 2×1 → `up` true across the full width.

This is pure geometry and very testable — make it thorough; directional bugs are subtle.

**B3. Floor mapping (`scr_get_floor_row_range`) — `each()` table:**

| input y | expected [min,max] | floor |
|---|---|---|
| 0, 1 | [0,1] | Attic |
| 2, 3 | [2,3] | First |
| 4, 5 | [4,5] | Ground |
| 6, 7 | [6,7] | Basement |

Also assert the out-of-range fallback returns `noone` (current behaviour) — and note this is a **spec drift**: the spec references `scr_grid_y_to_floor(y)` / `scr_floor_to_grid_rows(floor)`, but the code has `scr_get_floor_row_range`. Reconcile naming so tests match the real API.

**B4. Effective tags (`scr_get_effective_tags`)**
- No upgrade → returns base type tags only.
- Upgrade with `tags_added` → union of base + added, **no duplicates**.
- (Depends on `scr_get_upgrade`; stub or mark spec-only until upgrades land.)

**B5. Floor tag counting (`scr_count_tag_on_floor`)**
- Counts unique chambers carrying the tag on the same floor rows only.
- Respects the `max` cap.
- Ignores other floors and empty cells.

---

### Suite C: Minion State Machine (`test_minion_state.gml`)

Target functions (per spec; implement as they land): `scr_process_minion_states`, `scr_advance_progression`, `scr_apply_flat_tags`, `scr_apply_recovery`, `scr_handle_minion_terminal`, `scr_is_nerd_protected`.

> This system is **spec-only** in the current repo — there's no `scr_minion_state.gml` yet. Treat this suite as your acceptance criteria for when you build it. Write the tests first (TDD) against the spec; they'll also pin down ambiguities.

**C1. Progression advancement (`scr_advance_progression`)**
- First night on a track → counter starts at 0, increments to 1, applies any step whose `nights <= 1`.
- **Track change resets:** move minion from track A to track B → `progression_nights`/`step` reset before incrementing.
- **Same track across rooms does NOT reset** (move between two Lab rooms).
- Multiple steps crossed in one night (e.g. jump past thresholds) → all applicable tags applied, step index advances correctly.
- Terminal step reached → returns `true`, minion handled as terminal.

**C2. Flat tags (`scr_apply_flat_tags`)**
- `chance = 1.0` → always applied; `chance = 0.0` → never applied (deterministic).
- `max_stacks` respected: at cap, further applications skipped.
- Polarity routing: `"positive"` → `tags_positive`, else → `tags_negative`.

**C3. Recovery (`scr_apply_recovery`)**
- Removes exactly `remove_negative_per_night` oldest negative tags (index 0 first).
- Fewer negative tags than the removal count → empties, no underflow/crash.
- **Recovery does not reduce progression counter** — a minion at step N stays at step N after a Dormitory night.

**C4. Terminal actions (`scr_handle_minion_terminal`) — `each()`:**
| action | precondition | expected |
|---|---|---|
| `cull` | minion present | instance destroyed, chamber.minion = no |
| `flee` | minion present | has_fled set, instance destroyed, chamber.minion = no |
| `restore_cost` (affordable) | can afford cost | resources deducted, negative tags cleared, counter reset, minion survives |
| `restore_cost` (unaffordable) | cannot afford | falls through to `flee` behaviour |

**C5. Nerd exception (`scr_is_nerd_protected`)**
- Minion co-located with a Nerd → tag accumulation skipped that night.
- The Nerd herself is protected.
- Recovery still applies even when protected (prevents *accumulation*, not *recovery*).

**C6. Pipeline integration (`scr_process_minion_states`)**
- Empty grid / no minions → no-op, no crash.
- Chamber with minion but type lacking `minion_effects` → skipped.
- Recovery room takes precedence over progression (the `continue` path).
- Terminal in one chamber doesn't break processing of subsequent chambers.

---

### Suite D: Data Integrity / Contract Tests (`test_data_integrity.gml`)

These guard your JSON so a bad data file fails loudly instead of silently producing wrong numbers. Run against the real `datafiles/`.

**D1. Loader (`scr_load_chamber_types`)**
- After load, every entry in `chamber_type.data` has a matching key in `chamber_type.lookup`.
- `source_ally` is correctly derived from each file path (e.g. `"succubus"`).
- No duplicate `type` ids across files (a dup would silently overwrite the lookup index — worth asserting).

**D2. Schema validation (per chamber type entry)**
For every loaded type, assert:
- Required fields present & correctly typed: `type`, `display_name`, `size` ∈ {small, medium, large}, `tags` is a string array.
- `base` / `cost` are resource maps with **valid resource keys** (see D3).
- Each bonus rule has exactly one of `effects` or `effects_per_match` (not both), and a well-formed `condition`.
- If `minion_effects` present → it's *either* the recovery model *or* the progression/flat-tag model, not both; if progression present, `terminal_action` is set.

**D3. Resource key whitelist**
Centralise the valid resource keys (`value`, `power`, `stock`, `cash`, `lust_mana`, `humiliation_mana`, `fear_mana`, `influence`) and assert every cost/effect/base map only uses whitelisted keys. This catches typos like `"lusty"` that would silently produce nothing.

> ⚠️ **Current-code caveat:** the loader currently only loads `chamber_types/succubus.json`. The other ally files (necromancer, mad_scientist, cult_leader, aliens) and `upgrades/*.json` aren't loaded yet. D2/D3 will only cover succubus until you extend `_files`. That's fine — the test scales automatically as you add files.

**D4. Progression tracks (`progression_tracks.json`, spec-only)**
- Each track's `steps[].nights` is strictly ascending.
- Exactly one terminal step, and it's last.
- Every `minion_effects.progression_track` referenced by a chamber type resolves to an existing track id (cross-file referential integrity — a great thing to catch early).

---

### Suite E: Object & Event Smoke Tests (`test_ui_smoke.gml`) *(optional / lower priority)*

Use GMTL's simulation helpers for the few flows where event wiring matters. Keep this small and robust.

- **`obj_chamber` create:** `create(0, 0, obj_chamber)` → instance id > -1; verify `floor` is derived from `grid_y`; then `instance_destroy`.
- **Button interaction:** place an `obj_button_parent`, `simulateMousePosition(x, y)` + `simulateMouseClickPress(mb_left)`, assert the expected callback/state change (use a `spy()` on the handler to assert it fired with the right args).
- **Frame-dependent transitions:** use `simulateFrameWait(n)` then assert a lerped value reached its target — only for transitions you actually want pinned.

Don't over-invest here; these are guards against wiring regressions, not behaviour specs.

---

## 5. Coverage Strategy

Enable `gmtl_show_coverage = true` and track **function-level** coverage (GMTL's limit). To make the report meaningful:

- Pass functions directly to `expect()` with an args array so they're tracked:
  ```gml
  expect(scr_chamber_sum_resources, [_total, _base]).toHaveReturned(); // tracked
  ```
  rather than calling them as plain expressions.
- **Target:** every *named* engine function in `scr_chamber_calc.gml`, `scr_mansion_rooms.gml`, and (later) `scr_minion_state.gml` covered at least once. UI/presentation functions can be exempted.
- Treat the coverage table as a checklist of "what haven't I tested yet" rather than a number to hit.

---

## 6. Phased Rollout

**Phase 0 — Foundation (do first)**
- Create `scripts/test/` + `test_helpers.gml`.
- Add a test build / room with `gmtl_run_at_start = true`, coverage on.
- Write Suite B (grid geometry) — it's pure, needs no data loading, and proves the harness works end-to-end.

**Phase 1 — Chamber Engine**
- Suite A (A1–A7). Stub or wire `scr_get_upgrade` so upgrade tests are real.
- Add Suite D1/D2/D3 for succubus data.

**Phase 2 — Data-driven scale-out**
- As each ally JSON + upgrades file is added, the existing contract tests (D) automatically cover it. No new test code needed per room type — that's the payoff of data-driven design.

**Phase 3 — Minion State Machine**
- Implement `scr_minion_state.gml` against Suite C (write tests first). Add D4 track-integrity checks.

**Phase 4 — Polish & CI**
- Suite E smoke tests for key UI flows.
- Optional: file-based test harness + non-zero exit code for CI gating; pin RNG seed for any probabilistic assertions you keep.

---

## 7. Known Gaps / Spec Drift to Reconcile Before Testing

These are places where the spec and current code disagree — resolve them so tests assert against a single source of truth:

1. **`scr_get_upgrade()` returns `[]`.** Upgrade contribution (A4) and effective tags (B4) can't be meaningfully tested until the upgrade loader exists.
2. **Aura pass not implemented.** Spec describes it in the nightly sum; code doesn't do it yet (A8 is forward-looking).
3. **Floor-mapping API naming.** Spec: `scr_grid_y_to_floor` / `scr_floor_to_grid_rows`. Code: `scr_get_floor_row_range(y)`. Pick one and align tests + spec.
4. **Minion state system not implemented.** Entire Suite C is acceptance criteria for future work.
5. **Loader only reads succubus data.** Contract tests (D) will under-cover until the other ally files are added to `_files`.
6. **`scr_count_tag_on_floor(_chamber.y, ...)`** passes the instance's pixel `y`, not `grid_y`. Confirm this is intentional — floor mapping should key off grid row, and a pixel coordinate could give wrong results depending on cell size/offset. Worth a focused test (B5) to lock down the intended behaviour.

---

## 8. Quick Reference — GMTL API Cheat Sheet

| Need | Use |
|------|-----|
| Group tests | `suite(fn)` → `section(name, fn)` / `describe` → `test(name, fn)` / `it` |
| Table-driven cases | `each("name {0} {1}", fn, [[a,b], ...])` |
| Skip a test/section | `skip(...)` |
| Assert | `expect(actual).toBe / toBeEqual / toContain / toHaveLength / toHaveProperty / toThrow / toBeTruthy / toBeFalsy / toBeGreaterThan...` |
| Negate | `expect(x).never().toBe(y)` |
| Setup/teardown | `beforeAll`, `beforeEach`, `afterEach`, `afterAll` (inside suite/section, **not** test) |
| Create instance | `create(x, y, obj, [params])` → remember to `instance_destroy` |
| Simulate input | `simulateKeyPress/Release/Hold`, `simulateMouseClickPress/Release/Hold`, `simulateMousePosition`, gamepad variants |
| Advance time | `simulateFrameWait([frames])`, `simulateTimesource(...)`, `simulateCallLater(...)` |
| Fire an event | `simulateEvent(ev_type, ev_number, [instance_id])` |
| Fake async (HTTP/save) | use `async_load_map` in handlers + `simulateAsyncEvent(async_web, {...}, inst)` |
| Spy on a function | `var s = spy(fn); s.call([args]); expect(s).toHaveBeenCalledTimes(n) / toHaveBeenCalledWith([...])` |
| Coverage | set `gmtl_show_coverage true`; pass fn+args array to `expect()` to track it |
