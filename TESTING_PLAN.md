# Bound to the Bordello — Testing Plan

A testing strategy for **Bound to the Bordello** built on the [GameMaker's Testing Library (GMTL)](https://github.com/DAndrewBox/GM-Testing-Library) v1.2, which is already vendored into this project under `scripts/GMTL_*`.

This plan is written against the *current* code in the repo (`scr_chamber_calc.gml`, `scr_mansion_rooms.gml`, `scr_chamber_types.gml`) and the four technical specs:

- [`CHAMBER_SYSTEM_SPEC.md`](CHAMBER_SYSTEM_SPEC.md) — room side (contribution engine, grid geometry, `minions[]`/`clients[]` arrays, occupancy/capacity).
- [`MINION_SYSTEM_SPEC.md`](MINION_SYSTEM_SPEC.md) — **the** minion system: identity, flat tags, conversion, assignment, reclamation gating, upgrades, appearance. *This supersedes and retires the old `MINION_STATE_SPEC.md`; its nightly tag-status pipeline (progression tracks, cull/flee/restore) is now a designed-but-deferred mechanic in [`FUTURE_FEATURES.md`](FUTURE_FEATURES.md).*
- [`CLIENT_SYSTEM_SPEC.md`](CLIENT_SYSTEM_SPEC.md) — guests/clients: the fixed pool that generates income and supplies minions.

Where a spec describes behaviour that isn't implemented yet, it is flagged as **spec-only** so you know which tests are forward-looking. The minion and client systems are currently **spec-only** in the repo (no `scr_minions.gml`, `scr_minion_tags.gml`, or guest-pool data files exist yet), so Suites C and F read as acceptance criteria to write first (TDD).

---

## 1. Goals & Principles

The game's risk lives in its **data-driven simulation logic**, not its rendering:

- The Chamber Contribution Engine (JSON → nightly resource totals).
- The Minion system — conversion, the single flat tag array, room assignment/occupancy, reclamation gating, upgrades, appearance resolution.
- The Client/Guest system — fixed pool generation, visit-frequency rolls, the night funnel, and preference matching that drives income and conversion-cost discounts.
- Grid / adjacency / floor geometry on the `mansion_map` `ds_grid`.
- Resource economy math and cost/affordability checks (including the conversion-cost discount model).

These are almost all **pure functions** that read a grid + JSON + instance state and return numbers/maps/instances. That makes them ideal for fast, deterministic unit tests — the core reason to adopt GMTL here.

Principles:

1. **Test behaviour, not implementation.** Assert on returned totals, tag arrays, instance state, and pool contents — not on internal call order (except where an event *must* fire).
2. **Deterministic first.** The engine is deterministic except for `random()` in a few places: flat-tag application (deferred), blueprint selection, guest-pool generation, visit rolls, name draws, and appearance/quirk picks. Isolate those sources of non-determinism so tests are repeatable.
3. **One suite per system, one section per function/behaviour.** Keep suites small enough to read the failure output at a glance.
4. **Data-driven where it pays off.** Use `each()` for table cases (floor mapping, condition types, conversion templates, reclamation tiers) instead of copy-pasted tests.
5. **Coverage as a floor, not a target.** Enable GMTL's function coverage and aim to cover every *named* engine function; don't chase 100% on UI/presentation code.

---

## 2. What to Test (and what to skip)

| Layer | Examples | Strategy |
|-------|----------|----------|
| **Pure math / data** | `scr_chamber_sum_resources`, floor mapping, condition evaluation, tag counting, conversion-cost discount computation | Heavy unit coverage — highest value, cheapest. |
| **Grid geometry** | `scr_get_adjacent_chambers`, `scr_is_in_direction` (all sizes) | Unit tests with hand-built grids; use `each()` for size combos. |
| **Engine entry points** | `scr_calculate_chamber`, `scr_calculate_night_earnings`, `scr_convert_guest`, guest-pool generation, nightly visitor roll | Integration-style: build a small grid/pool, run the pass, assert totals/state. |
| **Data loading / validation** | `scr_load_chamber_types`, conversion templates, minion upgrades, guest pools, appearances — JSON schema integrity | Contract tests over the real `datafiles/`. |
| **Objects & events** | `obj_chamber` create, `obj_client` funnel states, UI buttons, camera | Light: use GMTL `create()` + `simulateEvent`/input for a few key flows. |
| **Presentation / feel** | lerp transitions, paper-doll animation, audio, minion sprite *art* | **Skip automated tests.** Manual playtest only — not worth the brittleness. (Appearance *resolution logic* is testable; the sprites themselves are not.) |

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
        test_minion_system.gml     #   suite: Minions — conversion, tags, assignment, reclamation, upgrades, appearance
        test_client_system.gml     #   suite: Clients/Guests — pool generation, visit rolls, funnel, preference matching
        test_data_integrity.gml    #   suite: JSON data contract tests (chambers + minions + clients)
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
    with (obj_chamber) instance_destroy();
    with (obj_minion)  instance_destroy();
    with (obj_client)  instance_destroy();
}
```

Use `beforeEach` / `afterEach` to reset state so tests don't leak into each other:

```gml
suite(function () {
    section("Minion System", function () {
        beforeEach(function () { test_setup_grid(); });
        afterEach(function  () { test_cleanup_instances(); });
        // ...tests...
    });
});
```

> **Important GMTL gotcha:** variables declared inside `before*`/`after*` hooks are *not* visible in the tests. Share state via globals or a struct (e.g. stash created instance ids on a global test-state struct) if you need to reference them later.

### 3.3 Determinism controls

Several sources of randomness must be tamed:

1. **Blueprint selection** (`define_floors` uses `irandom`). Don't unit-test the random pick; test `validate_template` and the layout→grid population with a fixed blueprint array instead.
2. **Guest-pool generation & visit rolls.** Pool generation draws names/tags/backstories/frequencies from distributions, and each night's visitor list is built by rolling `random() < visit_frequency`. For deterministic tests: (a) build pools/visitors directly via the helpers above with explicit values, or (b) seed the RNG at section start. For genuinely probabilistic behaviour (e.g. "a guest with `visit_frequency = 0.5` visits roughly half the time"), assert *statistical* properties over many iterations rather than exact outcomes — and pin a fixed seed so the run is reproducible.
3. **Name draws & appearance/quirk picks.** Conversion draws 3 random names; appearance resolves from tags via a priority table. Test name-draw logic with a seeded RNG (assert no duplicates, excludes already-used names) but test *appearance resolution* deterministically by feeding explicit tag arrays — the lookup is pure given the data file.
4. **Flat-tag `chance`** (`scr_apply_flat_tags`, deferred to future features). When that pipeline lands, either test with `chance = 1.0` / `chance = 0.0`, or seed the RNG; for probabilistic tags assert statistical properties over many iterations.

### 3.4 Running & gating tests

- GMTL runs suites automatically at game start (after `gmtl_wait_frames_before_start`, default 10 frames) via `GMTL_init`. Results print to the debug console.
- **Recommended:** add a dedicated *test room* / test build so you can run the full suite without booting into normal gameplay. Set `gmtl_run_at_start = true` for that build and keep it `false` in your play builds (see `GMTL_definitions.gml`).
- **Coverage:** flip `gmtl_show_coverage = true` in `scripts/GMTL_definitions/GMTL_definitions.gml` to get the function-level report after each run.
- **CI note:** GMTL is an in-engine runner, so there's no headless CLI out of the box. If you want CI gating later, build a small "test harness" room that writes pass/fail + coverage to a file (or `show_debug_message` → captured log) and exits with a non-zero code on failure. Treat this as a Phase 5 nicety, not a blocker.

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

### Suite C: Minion System (`test_minion_system.gml`)

Target functions (per [`MINION_SYSTEM_SPEC.md`](MINION_SYSTEM_SPEC.md); implement as they land): `scr_convert_guest`, `scr_create_minion` (shared internal), `minion_tag_add` / `minion_tag_remove` / `minion_has_tags` / `minion_refresh_appearance` (`scr_minion_tags.gml`), `scr_can_assign`, `scr_assign_minion`, and the minion-upgrade purchase procedure.

> This system is **spec-only** in the current repo — there's no `scr_minions.gml` or `scr_minion_tags.gml` yet. Treat this suite as your acceptance criteria for when you build it; write the tests first (TDD) against the spec so they also pin down ambiguities.
>
> **Note on scope:** the *old* nightly tag-status pipeline (progression tracks, cull/flee/restore terminals, `scr_process_minion_states`, nerd-protection halting accumulation) has been **retired** by this spec and moved to [`FUTURE_FEATURES.md`](FUTURE_FEATURES.md). Do **not** write tests for it here. When that pipeline is eventually implemented, add a dedicated suite (e.g. `test_minion_status_pipeline.gml`) covering progression advancement, flat-tag application, recovery, terminal actions, and nerd protection — see §7 note 4.

**C1. Tag helpers (`scr_minion_tags.gml`)**
- `minion_tag_add`: adds a missing tag; **no-op if already present (no stacks in v1)** — assert the array length doesn't grow on re-add.
- `minion_tag_remove`: removes *all* occurrences of a tag; no crash when the tag is absent.
- `minion_has_tags`: true only when the minion carries **every** tag in `_required`; accepts both an array and a single string; empty/`[]` requirement → true (vacuous).
- **Appearance sync invariant:** any path that mutates `tags` must call `minion_refresh_appearance()`. Assert `sprite_id` changes after add/remove when the priority table maps to a different sprite.

**C2. Conversion (`scr_convert_guest`) — the core integration test**
Build a guest with known tags/backstory/name and a conversion template, then assert:
- **Gate & cost:** gate fails (required room not built / required ally not secured) → no minion created, nothing paid. Cost unaffordable → same. Gate + cost pass → resources deducted by exactly `template.cost`.
- **Identity copy:** new minion's `guest_name` = guest name; `backstory` copied verbatim; `is_friend = false`; `quirk` = template quirk.
- **Tag inheritance + template application:** start from a copy of the guest's tags, then apply `tags_added` (each present) and `tags_removed` (removed *if present*). Assert the final set exactly — e.g. a `defiant` guest converted via `devotion_ritual` ends up with `devoted`, `loyal` added and `defiant` removed; an inherited tag like `dominant` **persists** verbatim.
- **History:** `history[0] = { cycle: current_cycle, text: template.text }` — the template's paragraph is always line item #1.
- **Default placement (step 6):** new minion placed in the guest's current chamber if it has free occupancy; otherwise falls back to any room with a free slot. Assert `current_chamber` is set and the chamber's `minions[]` contains the minion — conversion never strands a minion.
- **Guest destroyed & pool shrunk (step 7):** the guest instance is destroyed, removed from the fixed pool permanently, and marked so it never rolls again. The converted guest's *current-night* income was already banked (The Hunt runs after Production) but all future earnings are gone — assert the visitor-roll exclusion.
- **Name draw:** with a seeded RNG, 3 distinct names drawn from `minion_names.json`, excluding already-used minion names; on player skip/default the minion keeps `_guest.name`.

**C3. Friends (shared `scr_create_minion` path)**
- A friend minion (`is_friend = true`) uses **authored identity data**, not pool picks: skips the 3-pick naming, carries its archetype quirk and authored backstory/history. Assert no RNG name draw occurs for friends.

**C4. Room assignment & occupancy (`scr_can_assign` / `scr_assign_minion`)**
- **Occupancy gate:** a single-occupancy room (default) rejects a second minion; an `occupancy: N` room accepts up to N and rejects the N+1th.
- **Reclamation gate:** assigning to an obstacle with a `reclaim.requires_tags` set → allowed only if `minion_has_tags(_minion, requires_tags)` passes; omitted/empty `requires_tags` (Clutter) → any minion may be assigned.
- **Reference maintenance (`scr_assign_minion`):** reassigning a minion removes it from the old chamber's `minions[]`, pushes into the new one, and updates `current_chamber`. Assert no dangling references in either chamber after a move.
- **Invariant:** every minion is always in exactly one chamber (no roaming) — assert across create/convert/reassign that a minion never ends up with `current_chamber = no` outside the transient conversion window.

**C5. Reclamation gating & trade-off (`reclaim` blocks)**
- Use `each()` over tiers: tier 1 (Clutter, empty `requires_tags`) is open to all; higher tiers require their tag set and reject minions lacking it.
- While a minion is assigned to an obstacle, the obstacle **produces nothing** that night — assert its contribution is zero for that cycle (the "it *is* the work" trade-off).

**C6. Minion upgrades (`minion_upgrades.json` + purchase procedure)**
- **Gate:** `gate.requires_tags` must all be present on the minion and `gate.requires_rooms` must exist built, or the upgrade is not selectable (e.g. a `[broken]` quirk-restricted upgrade only applies to broken minions).
- **Cost & slot:** cost deducted; `upgrade_id` set. v1 policy: one-time — a second/different upgrade after one is installed is disallowed (assert the replacement guard).
- **Tag payload:** `tags_added` applied via `minion_tag_add()` and appearance re-synced. Because production bonuses read `minion_has_tag` on the chamber side, assert that purchasing an upgrade makes a previously-failing chamber bonus condition pass (composition with existing rooms — no new code needed).
- **History:** a purchase appends a history line item.

**C7. Appearance resolution (`minion_refresh_appearance`)**
- Feed explicit tag arrays against `minion_appearances.json`: first matching entry in file order wins; multiple matches → topmost (highest priority) sprite.
- No match → default base minion sprite.
- Re-resolution after a tag mutation tracks the most distinctive tag as tags escalate (e.g. `experimented` → `degraded` → `scarred`).

---

### Suite D: Data Integrity / Contract Tests (`test_data_integrity.gml`)

These guard your JSON so a bad data file fails loudly instead of silently producing wrong numbers. Run against the real `datafiles/`.

**D1. Chamber-type loader (`scr_load_chamber_types`)**
- After load, every entry in `chamber_type.data` has a matching key in `chamber_type.lookup`.
- `source_ally` is correctly derived from each file path (e.g. `"succubus"`).
- No duplicate `type` ids across files (a dup would silently overwrite the lookup index — worth asserting).

**D2. Chamber-type schema validation (per entry)**
For every loaded type, assert:
- Required fields present & correctly typed: `type`, `display_name`, `size` ∈ {small, medium, large}, `tags` is a string array.
- `base` / `cost` are resource maps with **valid resource keys** (see D3).
- Each bonus rule has exactly one of `effects` or `effects_per_match` (not both), and a well-formed `condition`.
- If `minion_effects` present → it's *either* the recovery model *or* the progression/flat-tag model, not both; if progression present, `terminal_action` is set. *(Note: per-night `minion_effects` are deferred to future features — validate only the schema shape for now.)*

**D3. Resource key whitelist**
Centralise the valid resource keys (`value`, `power`, `stock`, `cash`, `lust_mana`, `humiliation_mana`, `fear_mana`, `influence`) and assert every cost/effect/base map — including minion conversion-template costs and minion-upgrade costs — only uses whitelisted keys. This catches typos like `"lusty"` that would silently produce nothing.

> ⚠️ **Current-code caveat:** the loader currently only loads `chamber_types/succubus.json`. The other ally files (necromancer, mad_scientist, cult_leader, aliens) and `upgrades/*.json` aren't loaded yet. D2/D3 will only cover succubus until you extend `_files`. That's fine — the test scales automatically as you add files.

**D4. Minion data contract (spec-only)**
- **Conversion templates (`minion_conversion_templates.json`):** unique `id`s; each has a well-formed `cost` map (whitelisted keys), an optional `gate` with string-array `requires_rooms`/`requires_allies`, a non-empty `quirk`, and `tags_added` / `tags_removed` as string arrays. Cross-check: every `requires_rooms` entry resolves to an existing chamber type id; every `requires_allies` entry is a known ally.
- **Minion upgrades (`minion_upgrades.json`):** unique `id`s; `compatible_types` contains `"minion"`; well-formed `cost`; optional `gate.requires_tags` / `gate.requires_rooms` (rooms resolve to existing chamber types); `tags_added` is a string array.
- **Appearances (`minion_appearances.json`):** each entry has a non-empty `matches` array and a resolvable `sprite` reference; no two entries are identical (priority order must be meaningful).

**D5. Client data contract (spec-only)**
- **Guest pools (`guest_pools.json`):** each pool defines a size, a weighted tag distribution whose weights sum to 1 (or normalise cleanly), and a visit-frequency range within [0,1]. An optional `authored: true` entry supplies fixed name/backstory/tags instead of rolls — validate those fields are present when the flag is set.
- **Name & backstory pools (`client_names.json`, `backstories.json`):** non-empty; no duplicate names (names must be unique within a generated pool).

**D6. Progression tracks (`progression_tracks.json`) — deferred / future feature**
The nightly tag-status pipeline that consumes these is retired to [`FUTURE_FEATURES.md`](FUTURE_FEATURES.md). Only add these checks when that pipeline lands: each track's `steps[].nights` strictly ascending; exactly one terminal step, and it's last; every `minion_effects.progression_track` referenced by a chamber type resolves to an existing track id (cross-file referential integrity — a great thing to catch early).

---

### Suite E: Object & Event Smoke Tests (`test_ui_smoke.gml`) *(optional / lower priority)*

Use GMTL's simulation helpers for the few flows where event wiring matters. Keep this small and robust.

- **`obj_chamber` create:** `create(0, 0, obj_chamber)` → instance id > -1; verify `floor` is derived from `grid_y`; then `instance_destroy`.
- **Button interaction:** place an `obj_button_parent`, `simulateMousePosition(x, y)` + `simulateMouseClickPress(mb_left)`, assert the expected callback/state change (use a `spy()` on the handler to assert it fired with the right args).
- **Frame-dependent transitions:** use `simulateFrameWait(n)` then assert a lerped value reached its target — only for transitions you actually want pinned.

Don't over-invest here; these are guards against wiring regressions, not behaviour specs.

---

### Suite F: Client / Guest System (`test_client_system.gml`)

Target functions (per [`CLIENT_SYSTEM_SPEC.md`](CLIENT_SYSTEM_SPEC.md); implement as they land): guest-pool generation, the nightly visitor roll, the funnel state machine (`searching → moving → paying`), and the preference-matching / conversion-cost discount computation.

> This system is **spec-only** in the current repo — there's no `guest_pools.json`, pool-generation script, or discount function yet (the prototype only implements the three funnel states in `obj_client/Step_0.gml`). Treat this suite as acceptance criteria; write tests first against the spec.

**F1. Pool generation & seasonal growth**
- At playthrough start, build the initial pool from a given `guest_pools.json` entry: exactly N guests for the village, each with a name (unique within the pool), tags drawn from the town's weighted distribution, a backstory, and a `visit_frequency` within the profile's range. Use a seeded RNG so the draw is reproducible; assert *distributional* properties over many draws rather than exact picks.
- **Seasonal growth:** at the start of each new season, that season's new-town guests are added to the existing pool; existing guests remain and converted guests stay removed. Assert the pool only grows (by season) or shrinks (by conversion), never both for a single guest.
- **Authored entries:** an `authored: true` pool entry yields a fixed name/backstory/tags instead of rolls — assert no RNG is applied to those fields.

**F2. Nightly visitor roll**
- For each non-converted guest, the next night's visitors are built by rolling `random() < visit_frequency`. Assert: converted guests never roll again; a guest with `visit_frequency = 1.0` always visits and one with `0.0` never does (deterministic bounds); mid-range frequencies behave statistically over many iterations under a pinned seed.

**F3. Night funnel & capacity (`searching → moving → paying`)**
- A present guest spawns at the door and is funneled into rooms; assert it transitions through `searching → moving → paying` and that `target_room` is set then reset each cycle (transient).
- **Capacity:** a chamber holds up to `client_capacity` guests in its `clients[]` array. Assert a capacity-1 room rejects an overflow guest, while a multi-client room (e.g. The Bar) accepts several.
- **Production gating:** a room only produces for its guests if `requires.client` is satisfied **and** preference conditions are met — assert no income when either fails.

**F4. Income & conversion handoff**
- A satisfied guest pays on arrival (`paying` state → alarm): the flat per-night income is banked exactly once.
- **Conversion handoff (interface to Suite C):** on conversion, `name` → minion's `guest_name` (and default minion name if the player skips the 3-pick); `tags` copied verbatim; `backstory` copied verbatim; `visit_frequency`/`state`/funnel vars discarded; the instance destroyed and removed from the pool permanently. Assert the guest has already banked its current-night income (The Hunt runs after Production) but forfeits all future nights.

**F5. Preference matching & conversion-cost discount**
- The client spec owns computing the match/discount inputs from a guest's tag list: template base cost − up to **2 preference-tag matches** between the target `private` room (+ its upgrades) and the guest's tags − background-knowledge discount if Influence was spent on this client.
- Use `each()` over tag-overlap counts (0, 1, 2, 3+): assert the discount caps at 2 matches; a guest with no matching tags gets no preference discount; spending Influence unlocks both viewing the backstory *and* that client's personal conversion-cost discount (known-vs-unknown is UI state — the backstory always exists).

---

## 5. Coverage Strategy

Enable `gmtl_show_coverage = true` and track **function-level** coverage (GMTL's limit). To make the report meaningful:

- Pass functions directly to `expect()` with an args array so they're tracked:
  ```gml
  expect(scr_chamber_sum_resources, [_total, _base]).toHaveReturned(); // tracked
  ```
  rather than calling them as plain expressions.
- **Target:** every *named* engine function in `scr_chamber_calc.gml`, `scr_mansion_rooms.gml`, and (later) `scr_minions.gml` / `scr_minion_tags.gml` plus the client pool/funnel/discount functions covered at least once. UI/presentation functions can be exempted.
- Treat the coverage table as a checklist of "what haven't I tested yet" rather than a number to hit.

---

## 6. Phased Rollout

**Phase 0 — Foundation (do first)**
- Create `scripts/test/` + `test_helpers.gml` (including the `test_make_client` / `test_make_minion` builders).
- Add a test build / room with `gmtl_run_at_start = true`, coverage on.
- Write Suite B (grid geometry) — it's pure, needs no data loading, and proves the harness works end-to-end.

**Phase 1 — Chamber Engine**
- Suite A (A1–A7). Stub or wire `scr_get_upgrade` so upgrade tests are real.
- Add Suite D1/D2/D3 for succubus data.

**Phase 2 — Data-driven scale-out**
- As each ally JSON + upgrades file is added, the existing contract tests (D) automatically cover it. No new test code needed per room type — that's the payoff of data-driven design.

**Phase 3 — Minion System**
- Implement `scr_minions.gml` / `scr_minion_tags.gml` against Suite C (write tests first). Add D4 minion-data contract checks. Focus on conversion, tag helpers, assignment/occupancy, reclamation gating, upgrades, and appearance resolution.

**Phase 4 — Client System**
- Implement guest-pool generation + the funnel/discount logic against Suite F (write tests first). Add D5 client-data contract checks. Pin RNG seeds for pool-generation and visit-roll assertions you keep.

**Phase 5 — Polish & CI**
- Suite E smoke tests for key UI flows.
- Optional: file-based test harness + non-zero exit code for CI gating; pin RNG seed for any probabilistic assertions you keep.
- When the deferred nightly tag-status pipeline (progression tracks, cull/flee/restore) is eventually built from [`FUTURE_FEATURES.md`](FUTURE_FEATURES.md), add a dedicated suite plus D6 track-integrity checks — do not fold it into Suite C.

---

## 7. Known Gaps / Spec Drift to Reconcile Before Testing

These are places where the spec and current code disagree — resolve them so tests assert against a single source of truth:

1. **`scr_get_upgrade()` returns `[]`.** Upgrade contribution (A4) and effective tags (B4) can't be meaningfully tested until the upgrade loader exists.
2. **Aura pass not implemented.** Spec describes it in the nightly sum; code doesn't do it yet (A8 is forward-looking).
3. **Floor-mapping API naming.** Spec: `scr_grid_y_to_floor` / `scr_floor_to_grid_rows`. Code: `scr_get_floor_row_range(y)`. Pick one and align tests + spec.
4. **Minion system not implemented — and the old state machine is retired.** The entire minion system (Suite C) is acceptance criteria for future work, *and* it now targets a different design than before: [`MINION_SYSTEM_SPEC.md`](MINION_SYSTEM_SPEC.md) supersedes `MINION_STATE_SPEC.md`, so the nightly tag-status pipeline (progression tracks, cull/flee/restore terminals, nerd-protection halting accumulation) is **deferred** to [`FUTURE_FEATURES.md`](FUTURE_FEATURES.md). Don't write tests for that retired pipeline here; when it lands, give it its own suite.
5. **Client system not implemented.** The guest pool, visit rolls, funnel beyond the three prototype states, and the conversion-cost discount model (Suite F) are all forward-looking — only `obj_client/Step_0.gml`'s `searching/moving/paying` states exist today.
6. **Loader only reads succubus data.** Contract tests (D) will under-cover until the other ally files, minion data files (`minion_conversion_templates.json`, `minion_upgrades.json`, `minion_appearances.json`), and client data files (`guest_pools.json`, `client_names.json`, `backstories.json`) are added to `_files`.
7. **`scr_count_tag_on_floor(_chamber.y, ...)`** passes the instance's pixel `y`, not `grid_y`. Confirm this is intentional — floor mapping should key off grid row, and a pixel coordinate could give wrong results depending on cell size/offset. Worth a focused test (B5) to lock down the intended behaviour.

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

Full documentation for GMTL can be found here:  https://github.com/DAndrewBox/GM-Testing-Library/wiki/Documentation
