# Playable Turns Plan — "Two Turns, Get a Feel"

**Goal:** A player can run **Day → Night → Reckoning for 1–2 cycles of Spring** and *feel* the game: make management decisions by day (build / assign / reclaim), watch clients arrive and rooms earn at night, see resources move, and have at least one realistic chance to convert a guest into a minion.

**Definition of done:** Start the game → place ≥1 room and reassign a minion during Day 1 → End Day → watch guests funnel in and settle → Reckoning shows what was earned and resources update → repeat for cycle 2, converting one guest via The Hunt. No debug console required to follow any of it.

---

## Current State (no work needed)

- ✅ `obj_game_manager` — period/season/cycle state machine (`end_turn()`), resource structs
- ✅ Mansion grid (`global.mansion_map` 10×8), per-floor JSON layouts, room instances + sprites, selection highlight, camera scroll arrows
- ✅ Chamber contribution engine — base/bonuses/adjacency pipeline, `count_adjacent_tag` condition, real upgrade loader + `scr_get_upgrade()`, `minion_has_tag` / `upgrade_present` conditions, and the nightly-sum aura pass (P0 tasks 2–5 done; GMTL suite in `scripts/test_chamber_calc`).
- ✅ Guest pool generation — `scr_get_new_clients("village")`: 9 guests with unique names, backstories, tags (`client_pools.json`, `names.json`, `backgrounds/`)
- ✅ Two starting minions (PC + friend) placed via `scr_create_first_minions`; minion lerp movement
- ✅ Resource bar UI drawing all primary + secondary resources

---

## P0 — Make a turn actually happen *(core plumbing)*

- [ ] **1. Starting resources & tuning** (`obj_game_manager` Create)
  Player starts with 0 of everything and can't afford anything. Grant a starting balance (cash + some mana flavours) sized so the player can buy ~2–3 rooms in cycle 1 and one conversion is reachable by cycle 2 (or lower template costs for playtest).
  *Done when:* resource bar shows non-zero values at start; first build purchase is affordable.

- [x] **2. Implement `count_adjacent_tag` condition** (`scr_eval_condition`, `scr_chamber_calc.gml`)
  Missing from the switch — falls to default ("Unknown chamber condition type") and returns false. Count unique adjacent chambers carrying the tag via effective tags, capped at optional `max`. Without this, **all three primary-resource collectors (Counting Room → Value, Mana Crystal → Power, Filing Room → Stock) produce nothing**.
  *Done when:* a Counting Room next to two `tips` rooms earns +2 Value; add GMTL cases alongside the existing adjacency tests.

- [x] **3. Upgrade loader + real `scr_get_upgrade()`** (`scr_chamber_types.gml`, `datafiles/upgrades/succubus.json`)
  `scr_get_upgrade()` is a stub returning `{}` and no code loads `upgrades/*.json`. Add a loader (mirror `scr_load_chamber_types`) and fix the data key mismatch: effects use `lust_mana` / `humiliation_mana` but resource keys are `lust` / `humiliation`.
  *Done when:* an installed upgrade's `effects` appear in the chamber breakdown and its `tags_added` show up in `scr_get_effective_tags` (feeding neighbour collectors).

- [x] **4. Aura pass in nightly sum** (`scr_calculate_night_earnings`, `scr_chamber_calc.gml`)
  Spec: second pass after per-chamber totals — each chamber with an `aura` applies it once per unique adjacent chamber's accumulated total (reuse the one-cell-ring adjacency scan + dedup). Independent of the adder's own prerequisites.
  *Done when:* a Laundry next to two rooms adds its `{stock, influence}` aura to both neighbours' totals and to the grand total; the adder itself gets nothing.

- [x] **5. Complete the condition table** (`scr_eval_condition`)
  Add `minion_has_tag` (any occupied minion slot carries the tag) and `upgrade_present` per the spec's Condition Types table, so data can use them before they're needed by minion-upgrade composition.

- [ ] **6. Apply nightly production to resources** (`obj_game_manager.end_turn()`)
  Currently `scr_calculate_night_earnings()` results are only `show_debug_message`'d. Sum `.earnings` into `global.primary_resources` / `global.secondary_resources` (split by resource key).
  *Done when:* after the first night, cash/lust/value/etc. increase by exactly the calculated totals.

- [ ] **7. Chamber capacity from type definition** (`obj_chamber` Create)
  `max_clients = 1` and `max_minions = 1` are hardcoded; read `client_capacity` (default 1) and minion occupancy from the chamber type def, per CHAMBER_SYSTEM_SPEC §instance variables. Resolve the schema mismatch: spec says `occupancy`, but succubus.json uses `"minion_capacity": 999` for the Lobby — pick one key and normalise data + code.
  *Done when:* The Bar holds 5 clients, The Lobby many minions.

- [ ] **8. Occupied-slot semantics for `clients[]` / `minions[]`**
  Spec: slots hold `noone` for empty; the `requires.client` gate checks "at least one non-`noone` entry" and `clients_present_count` returns occupied-slot count (same for `minion_assigned`). Current code uses `array_length`, which overcounts once the funnel pre-fills slots to capacity.
  *Done when:* a capacity-5 room with 2 guests counts as 2, not 5; empty `noone` slots never satisfy gates.

- [ ] **9. Per-cycle state reset**
  Reset every chamber's `clients[]` to `noone` at night start (spec: "reset each cycle"), and clear funnel vars on guests (`target_room`, `state`).
  *Done when:* no guest or client slot carries over between cycles.

- [ ] **P0 note — reclamation production gate:** fold into task 12 below: a chamber with `is_reclaiming` / active clearing progress produces nothing that night (GDD §10 trade-off) — add to the prerequisite gate in `scr_calculate_chamber`.

## P1 — Day-phase agency *(the management feel)*

- [ ] **10. Build UI + placement logic**
  Room-type list (from `chamber_type_defs`) filtered by floor via `placement.floors`; click a grid cell to place; validate footprint (small 1×1 / medium 2×1 / large 2×2) and empty cells; deduct cost from resources; create `obj_chamber` + update `global.mansion_map`.
  *Done when:* player buys & places The Bar on the Ground floor in cycle 1; placement is rejected off-floor, on occupied cells, or when broke.

- [ ] **11. Minion assignment UI**
  Select minion → select target room → move via existing `scr_move_minion` with occupancy check (`max_minions`). Wire into the selection panel and/or the currently-dead "Peon" / `NEXT_MINION` button. Must also allow assigning to obstacle rooms (feeds task 12).
  *Done when:* player can swap PC/friend between rooms and put a minion on a cluttered room.

- [ ] **12. Reclamation pipeline** (`reclaim` blocks already in data)
  While a minion is assigned to an obstacle, decrement `nights_to_clear` each night (progress, plan and payment all retained if the minion is reassigned or terminated — spec §Clearing Progression). **Planned builds:** assignment also sets the site's planned build (any type valid for its floor, picked from the obstacle panel with per-candidate adjacency previews); cost is paid separately via `Pay ▸` any time before clearing, and changing a paid plan settles the cost delta. At 0: paid → the room materialises that night (Reckoning beat); unpaid → the site becomes a blueprint (ghost of the planned room) that can be funded or re-planned later. Enforce `requires_tags` at assignment time (Clutter = any minion). Add the production gate: a room being reclaimed produces nothing that night. Note: the friend starts assigned to the cluttered room beside the boudoir, so this gives them automatic first work.
  *Done when:* a minion on a Cluttered Room clears it after 2 nights — materialising its paid plan, or becoming a fundable blueprint if unpaid; reassigning the minion keeps progress, plan and payment; an obstacle with a minion assigned shows zero output in the breakdown.

## P2 — Night phase *(the operation feel)*

- [ ] **13. Visit frequency + nightly visitor roll** (`client_pools.json`, `obj_client` Create, pool gen)
  Add a per-pool frequency range to `client_pools.json`; roll each guest's `visit_frequency` at generation (replaces the hardcoded 0.6); build tonight's list with `random() < visit_frequency`. Converted guests never roll again.
  *Done when:* successive nights bring different subsets of the village pool.

- [ ] **14. Funnel state machine** (`obj_client/Step_0.gml` — currently empty)
  Spawn visible clients at a door point → `searching` (score rooms by guest-tag vs room-tag overlap, pick best with free capacity; fallback: any room with capacity) → `moving` (lerp to chamber, set `target_room`, push into `chamber.clients[]`) → `paying` (stay for the night).
  *Done when:* on End Day you can watch guests walk in and settle; multi-client rooms fill multiple slots. *(Matches TESTING_PLAN Suite F3 acceptance criteria.)*

- [ ] **15. Phase feedback UI** (`obj_ui_manager`)
  Show current phase + season/cycle (e.g. "Spring — Cycle 1, Night"); at Reckoning show a short earnings summary using the per-room breakdown lines from `scr_calculate_night_earnings()` instead of debug messages; make the Done button context-aware ("End Day" / "End Night").
  Note (PR #47 review): aura applied to an *inactive* room currently lands only in the grand total — `inactive_rooms` entries carry no result/lines, so there's no room-level breakdown line for it. Decide here whether inactive entries should also carry a result map.
  *Done when:* player can tell which phase they're in and what the night earned without the debug console.

## P3 — The Hunt / conversion *(the strategic tension)*

- [ ] **16. Add `private` tag to room types** (`datafiles/chamber_types/succubus.json`)
  No chamber currently carries `private`, which The Hunt is gated on (GDD §2/§7). Tag the Boudoir (and any other suitable private rooms).

- [ ] **17. Conversion template data** — create `datafiles/minion_conversion_templates.json`
  Per MINION_SYSTEM_SPEC §Conversion: three templates (devotion / breaking / terror) with cost, gate, quirk, tags_added/removed, text. Keep gates simple for this milestone (e.g. devotion requires the boudoir; terror ungated).

- [ ] **18. `scr_convert_guest(_guest, _template)`**
  Validate gate + affordability; apply tag-match discount (up to 2 matches between the private room (+ its upgrades) and the guest's tags); create minion (copy tags/backstory verbatim, `guest_name`, history[0] = template text, apply tags_added/removed); assign to the conversion room if it has free occupancy else any free slot; destroy the guest instance.
  *Done when:* converting a tag-matched guest in a matching private room costs less than full price; the guest is gone from all future visitor rolls. *(TESTING_PLAN Suite C2.)*

- [ ] **19. Hunt UI** (night phase)
  Select a present guest + a `private` room → template list (name / description / cost with discount shown) → confirm → name pick of 3 (or default to guest name).
  *Done when:* player completes one full conversion in-game by cycle 2.

## P4 — Feel polish *(optional for the milestone, high value)*

- [ ] **20. Day/night presentation** — swap `spr_sky_day` / `spr_sky_night` on phase change; paper-doll slide-in for panels (button shiver/slide already exists).
- [ ] **21. Guest info display** — hover or panel shows guest name + tags/backstory. (Influence-gated reveal can wait; showing it freely is fine for playtest.)
- [ ] **22. Room upgrade installation UI** *(optional)* — pick one installed upgrade per room from `datafiles/upgrades/succubus.json`. Needed only if upgrades should matter within 2 turns; otherwise defer (task 3 keeps the data safe either way).

---

## Explicitly out of scope for this milestone

- Seasonal pool growth / town choice, allies & gateway rooms, friend narrative beats
- Nightly tag pipeline / recovery (deferred per FUTURE_FEATURES §1), minion upgrade purchases
- Save system, town tag-bias weighting (flat frequency range is fine), achievement checks beyond a stub

## Suggested build order

P0 (tasks 1–9) → P2 (13–15) gives you a **watchable, correctly-earning** turn first; then P1 (10–12) adds day-phase agency; then P3 (16–19) completes the loop with conversion. P4 (20–22) can be interleaved whenever presentation feels flat during playtest.
