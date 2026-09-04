# Chamber Contribution System — Technical Specification

## Overview

Each chamber (room instance) produces resources each night based on its **type definition**, **installed upgrade**, and **spatial context** (adjacent rooms, floor tag density). The system is fully data-driven: room types and upgrades are defined in JSON; a small set of pure evaluation functions calculate contributions against the live `mansion_map` grid.

Two public entry points serve all use cases:
- **Per-chamber calculation** → returns total contribution + itemised breakdown (for UI inspection).
- **Nightly sum** → iterates all chambers, accumulates totals (for end-of-cycle earnings).

## File Layout

```
datafiles/
    chamber_types/
        succubus.json           ← base rooms always available (Boudoir, Bar, Dormitory, etc.)
        necromancer.json        ← Morgue/Graveyard + post-unlock necro rooms
        mad_scientist.json      ← Basic Lab + science rooms
        cult_leader.json        ← Ritual Room + cult rooms
        aliens.json             ← Cow Shed + alien rooms
    upgrades/
        succubus.json           ← generic/succubus upgrades
        necromancer.json
        mad_scientist.json
        cult_leader.json
        aliens.json
    progression_tracks.json     ← named degradation/recovery tracks (see MINION_STATE_SPEC.md)

scripts/
    scr_chamber_types.gml       ← JSON loaders, lookup tables, floor mapping helpers
    scr_chamber_calc.gml        ← evaluation engine (gating, base, bonuses, upgrades, adjacency)
    scr_minion_state.gml        ← minion tag/progression processing (see MINION_STATE_SPEC.md)

objects/
    obj_chamber/                ← instance: holds type, grid pos, minion/client refs, upgrade
```

The `succubus` set is the default/base pool. Ally-named files contain that ally's gateway room plus any additional rooms unlocked after securing them. Adding a new ally = adding one JSON file + one entry in the loader array.

## Chamber Type Definition (JSON Schema)

Each entry in a `chamber_types/*.json` array:

```json
{
  "type": "boudoir",
  "display_name": "The Boudoir",
  "size": "small",
  "tags": ["private", "luxury"],
  "placement": { "floors": ["GROUND"] },
  "requires": { "minion": true, "client": true },
  "cost": { "cash": 50, "lust_mana": 10 },
  "base": { "lust_mana": 5, "value": 5 },
  "bonuses": [ ... ],
  "aura": { ... },
  "minion_effects": { ... }
}
```

| Field | Type | Purpose |
|---|---|---|
| `type` | string | Unique ID; matches the `chamber_type` variable on the instance and the sprite naming convention. |
| `display_name` | string | Human-readable name for UI. |
| `size` | string (`"small"` / `"medium"` / `"large"`) | Footprint of the room; maps to the `ROOM_SIZE` enum (0/1/2) and `global.size_dims` (1×1 / 2×1 / 2×2). Used by the fixed-slot placement system to match a type to a reclaimed slot. Larger footprints touch more adjacent cells, so they feed more collectors/adders for free. |
| `tags` | string[] | Intrinsic tags carried by this room type (e.g. `"private"`, `"luxury"`, `"dungeon"`). Used in synergy/tag-count calculations and as the input to collectors. |
| `placement` | map (optional) | Placement restrictions. `floors`: array of FLOOR values the room may occupy; `walls`: `"interior"` / `"exterior"`. Absent = any floor/wall. Supports per-room zoning. |
| `requires.minion` | bool | If `true`, no production occurs without **at least one** assigned minion instance. If `false`, the room is **passive** (no minion needed) — used by collectors, adders, and reclamation obstacles. *(Earlier drafts stated "all rooms require a minion"; this was relaxed to allow minion-free utility/collector rooms.)* |
| `requires.client` | bool | If `true`, no production occurs without **at least one** guest present that night. Most rooms are `true`; utility rooms (Dormitory, Inner Sanctum) are `false`. |
| `client_capacity` | int (optional, default 1) | Maximum number of guests this chamber can hold simultaneously. Most rooms omit it (capacity 1). Multi-client rooms (e.g., The Bar: `"client_capacity": 4`) accept multiple guests; the `clients_present_count` condition and scalable bonuses use this count. |
| `cost` | map (resource → int) | Secondary resources spent to build this room. Only list non-zero costs; absent keys cost 0. |
| `base` | map (resource → int) | Flat resource output per night when prerequisites are met. Always applies (no conditions). May be empty `{}` for rooms that only produce via bonuses, aura, or abilities. |
| `bonuses` | array of rule objects | Conditional additional outputs (see below). |
| `aura` | map (optional) | Resource map applied to each **unique adjacent chamber** each night (see [Aura Effects](#aura-effects-adders)). Used by adder/support rooms; independent of the room's own production. |
| `occupancy` | int (optional, default 1) | Max minion instances the room can hold simultaneously (e.g., Dormitory = 3). Rooms with a single slot simply omit it. See [Minion Effects](#minion-effects-room-side). |
| `minion_effects` | map (optional) | Rules for how this room modifies the minions assigned to it each night. See [Minion Effects](#minion-effects-room-side) below and [`MINION_STATE_SPEC.md`](MINION_STATE_SPEC.md) for full details. |
| `reclaim` | map (optional) | Present on reclamation obstacle types only — `{ tier, nights_to_clear, requires_tags }`. See [Reclamation Obstacles](#reclamation-obstacles). |
| `history_flavour` | string[] (optional) | Pool of random flavour text lines for the minion history system. Each night, a low-chance roll per assigned minion may append one line drawn from this array to their `history` (see [`MINION_SYSTEM_SPEC.md`](MINION_SYSTEM_SPEC.md) §History). Presentation only — never mechanical. If the pool grows too large for comfort, extract to a separate JSON file keyed by type ID. |

The loader tags each entry with a `source_ally` string (derived from the filename) for build-gating and flavour, but the calculation engine ignores it.

## Bonus Rule Schema

Each element in the `bonuses` array:

```json
{
  "id": "bar_synergy",
  "description": "+5 Cash if adjacent to a Bar",
  "effects": { "cash": 5 },
  "condition": { "type": "adjacent_room_type", "room_type": "bar" }
}
```

Or for scaled/count-based rules:

```json
{
  "id": "floor_luxury_count",
  "description": "+5 Cash per 'luxury' tag on this floor (max 5)",
  "effects_per_match": { "cash": 5 },
  "condition": { "type": "count_tag_on_floor", "tag": "luxury", "per": 1, "max": 5 }
}
```

| Field | Purpose |
|---|---|
| `id` | Unique identifier within the type (used as a key in UI breakdown). |
| `description` | Player-facing text for the breakdown panel. |
| `effects` | Flat resource map applied when condition is met (boolean conditions). |
| `effects_per_match` | Resource map multiplied by the integer result of a count condition. Use this **or** `effects`, not both. |
| `condition` | Typed condition object (see table below). |

## Condition Types

Evaluated by `scr_eval_condition(chamber, condition_map)`. Returns `true`/`false` for boolean conditions or an integer for count conditions.

| `condition.type` | Parameters | Returns | Meaning |
|---|---|---|---|
| `adjacent_room_type` | `room_type` (string or `"*"`), optional `direction` (`"up"`, `"down"`, `"left"`, `"right"`) | bool | Any adjacent chamber matches the given type. When `direction` is set, only chambers strictly touching that side of the room count (edge-touching adjacency, no diagonals — see [Directional Adjacency](#directional-adjacency)). |
| `count_tag_on_floor` | `tag` (string), `per` (int, value per match), `max` (int cap) | int | Count of unique chambers on the same floor carrying that tag (including upgrade-added tags). Capped at `max`. |
| `count_adjacent_tag` | `tag` (string), optional `max` (int cap) | int | Count of unique adjacent chambers carrying that tag (including upgrade-added tags). Capped at `max` if present. Used by collectors to harvest a tag from neighbouring rooms into a primary resource. |
| `clients_present_count` | — | int | Number of clients in this chamber's `clients[]` array for the night. Used by scalable/overflow rooms whose output grows with occupancy (e.g., Bar, Glass Room). |
| `minion_assigned` | — | bool | A minion instance is present in this chamber. |
| `minion_has_tag` | `tag` (string) | bool | The assigned minion carries a specific tag. |
| `floor_is` | `floor` (FLOOR enum value or name string) | bool | This chamber is on the specified floor. |
| `upgrade_present` | `upgrade_id` (string) | bool | A specific upgrade is installed in this chamber. |

New condition types are added by extending the switch in `scr_eval_condition`. The JSON schema shape does not change.

## Upgrade Definition (JSON Schema)

Each entry in an `upgrades/*.json` array:

```json
{
  "id": "whip_set",
  "display_name": "Whip & Chain Set",
  "compatible_types": ["boudoir", "sex_dungeon"],
  "cost": { "cash": 25, "humiliation_mana": 8 },
  "effects": { "humiliation_mana": 3 },
  "tags_added": ["dungeon"]
}
```

| Field | Purpose |
|---|---|
| `id` | Unique upgrade identifier. Stored on the chamber instance as `upgrade_id`. |
| `display_name` | UI text. |
| `compatible_types` | string[] of room type IDs this upgrade can be installed in. `"*"` means any room. One upgrade per room (enforced at assignment). |
| `cost` | Resource map, same convention as chamber costs. |
| `effects` | Flat resource bonus added to the chamber's nightly output while installed. |
| `tags_added` | string[] of tags appended to the chamber's effective tag list while installed. Affects other rooms' tag-counting bonuses and collectors. |

## Effective Tags

A chamber's **effective tags** = its type's intrinsic `tags` + any `tags_added` from its installed upgrade. All tag-based calculations (floor counts, adjacency counts, synergy checks) use effective tags, not just base type tags. This means installing an upgrade that adds a tag can make the room feed a new collector or trigger a neighbour's bonus.

## Minion Effects (Room-Side)

The optional `minion_effects` block defines how a room modifies **each** minion assigned to it each night. This is **not** part of the resource contribution calculation — it is processed separately by the minion state system after production resolves.

Two sub-models exist:

| Sub-model | Field | Purpose |
|---|---|---|
| Degradation / Progression | `progression_track`, `tags_per_night`, `terminal_action` | Advances a named progression track and/or applies flat tags each night. Used by ally gateway rooms (Lab, Morgue, Ritual Room, Cow Shed). |
| Recovery | `recovery.remove_per_night` | Removes tags from the minion's tag list each night (oldest first). Used by Dormitory and similar rest rooms. |

A room uses **one** sub-model or the other, not both. The full schema, progression track definitions, processing pipeline, and terminal actions are specified in [`MINION_STATE_SPEC.md`](MINION_STATE_SPEC.md).

### Occupancy (Multi-Slot Rooms)

Most rooms hold a single minion. A type may declare `"occupancy": N` to hold **up to N** distinct minion instances at once (e.g., Dormitory: `"occupancy": 3`). Rules:

- The instance variable is an array of up to `N` minion references; assigning beyond capacity is blocked.
- `minion_effects` apply **independently per assigned minion** — three minions in the Dormitory each get their own nightly recovery pass.
- Extra occupants do **not** scale the room's resource contribution: base/bonus output stays flat regardless of how many slots are filled. Occupancy is a capacity for stacking state (recovery, progression) on multiple minions, not an output multiplier.
- `requires.minion` remains boolean "at least one assigned." Rooms with occupancy > 1 that produce nothing can still be `requires.minion: false`.

## Aura Effects (Adders)

The optional `aura` block lets a chamber contribute resources to its **neighbours** rather than to itself. This is the mechanism behind adder/support rooms (e.g., Laundry, Shower), which buff adjacent production rooms.

```json
"aura": { "stock": 1, "influence": 1 }
```

- `aura` is a resource map applied to **each unique adjacent chamber** once per night.
- It is independent of the adder's own prerequisites — adders are typically `requires.minion: false`, so they buff neighbours even when unstaffed (the "errand" animation where a neighbouring minion drops in to do the task is presentation only, with no mechanical cost).
- An aura applies **once per unique neighbour**, using the same one-cell-ring adjacency scan + `ds_set` dedup as elsewhere, and does not apply to the adder itself.
- Aura contributions are additive on top of the target chamber's own base/bonus/upgrade totals.

### Processing order

Aura is resolved as a **separate pass after** all per-chamber totals are computed (see [Nightly Sum](#nightly-sum)). This guarantees an adder buffs a neighbour's *final* total, and that two adjacent adders both apply to the same target without ordering dependencies.

## Calculation Pipeline

`scr_calculate_chamber(chamber_instance)` executes in order:

1. **Prerequisite gate.** Check `requires.minion` (at least one entry in `minions[]`) and `requires.client` (at least one entry in `clients[]`). If unmet, return immediately with `{ total: {}, lines: [{ detail: reason }], active: false }`. No further evaluation.
2. **Base output.** Add all entries from the type's `base` map to the running total. Record one breakdown line.
3. **Bonus rules.** For each rule in `bonuses[]`: evaluate its condition against the live grid. If triggered, apply `effects` (or `effects_per_match × count`). Record a breakdown line per triggered rule.
4. **Upgrade contribution.** If an upgrade is installed and compatible: add its `effects` to the total. Record a breakdown line.

Return value: `{ total: map, lines: array, active: bool }`. Aura is **not** part of this per-chamber calculation — it is applied to neighbours in the nightly-sum aura pass (see [Aura Effects](#aura-effects-adders)).

## Nightly Sum

`scr_calculate_night_earnings()` runs in two passes:

1. **Per-chamber totals.** Iterate every cell of `mansion_map`, deduplicate multi-cell rooms via a `ds_set`, call `scr_calculate_chamber` on each unique instance, and accumulate all `.total` maps into one grand total. Inactive chambers contribute 0.
2. **Aura pass.** For each chamber carrying an `aura`, apply it to every unique adjacent chamber's accumulated total (see [Aura Effects](#aura-effects-adders)).

A variant, `scr_get_night_summary()`, additionally partitions results into `active_rooms[]` and `inactive_rooms[]` (with reasons) for the end-of-cycle "Reckoning" screen.

## Adjacency Logic

Chambers occupy 1×1, 2×1, or 2×2 cells on the grid (per `global.size_dims`). To find neighbours:

1. Determine the subject chamber's bounding box from its `grid_x`, `grid_y`, and size dimensions.
2. Scan all cells in a one-cell ring around that bounding box.
3. Skip cells that fall within the subject's own bounding box.
4. Read each cell from `mansion_map`; skip `-1` (empty) and non-instance values.
5. Deduplicate via `ds_set` (a multi-cell neighbour will appear in multiple ring cells).

This correctly handles all size combinations without special-casing, and is shared by the bonus conditions (`adjacent_room_type`, `count_adjacent_tag`) and the aura pass.

### Directional Adjacency

The optional `direction` parameter on `adjacent_room_type` narrows a match to chambers touching a specific side of the subject room. It accepts `"up"`, `"down"`, `"left"` or `"right"` (screen-space: up = lower `grid_y`).

Implemented by `scr_is_in_direction(subject, neighbour, direction)`. The check is **strict edge-touching adjacency** — no diagonals — and compares full bounding boxes so multi-cell rooms work correctly:

- A neighbour is **"up"** if its bottom edge touches the subject's top edge with horizontal overlap.
- A neighbour is **"down"** if its top edge touches the subject's bottom edge with vertical overlap.
- A neighbour is **"left"** if its right edge touches the subject's left edge with vertical overlap.
- A neighbour is **"right"** if its left edge touches the subject's right edge with vertical overlap.

A room can satisfy more than one direction at once (e.g. a 2×1 room directly above a 2×1 room is both "up" and, for overlapping columns, counts as up across its full width). Diagonal-only contact never matches any direction.

## Floor Mapping

The grid is 10 columns × 8 rows. Floor is derived from `grid_y`:

| `grid_y` | Floor |
|---|---|
| 0–1 | Attic (`FLOOR.ATTIC`) |
| 2–3 | First (`FLOOR.FIRST`) |
| 4–5 | Ground (`FLOOR.GROUND`) |
| 6–7 | Basement (`FLOOR.BASEMENT`) |

Two helper functions: `scr_grid_y_to_floor(y)` and `scr_floor_to_grid_rows(floor) → [min, max]`. The floor is computed at instance creation from the passed `grid_y` and stored on the instance.

### Floor Access & Reclamation Gating

Floors are **not** unlocked by a simple seasonal timer. Instead, each floor's reclamation obstacles carry `requires_tags` that can only be satisfied once the player has secured the relevant ally (who grants those tags via minion effects, upgrades, or scripted events):

| Floor | Reclamation Tier | Gating Mechanism |
|---|---|---|
| Ground | Clutter (tier 1) | No tag requirement — any minion can clear. Available from the start of Spring. |
| Basement | Rubble/Hazards (tier 2–3) | Requires tags granted by the **Necromancer** ally (secured in Summer). Exact tags TBD via playtest. |
| First Floor | Hazards/Seals (tier 3–4) | Requires tags granted by the **Cult Leader** ally (secured in Autumn). Exact tags TBD via playtest. |
| Attic | Seals (tier 4) | Requires a high-level tag or combination; likely gated by final-season progression. TBD. |

A room's `placement.floors` further restricts which floors it may occupy *once that floor is accessible*, so per-room zoning composes with reclamation gating. The exact tag-to-floor mapping and tier assignments are data-driven in the obstacle JSON and subject to playtest tuning.

## Reclamation Obstacles

Certain chamber types represent blocked zones in the Ruin State (GDD §10): `cluttered`, `rubble`, `hazards`, `seals`. They are **pre-placed by layout data** (not built by the player), produce nothing (`base: {}`, no bonuses, `requires.minion: false`), and carry a `reclaim` block:

```json
"reclaim": { "tier": 2, "nights_to_clear": 4, "requires_tags": ["sturdy"] }
```

| Field | Type | Purpose |
|---|---|---|
| `tier` | int | Reclamation tier (1 = Clutter … 4 = Seals). Higher tiers take longer and require more capable minions. |
| `nights_to_clear` | int | Base number of nights to clear once a minion is assigned. Tags/upgrades can reduce this duration. |
| `requires_tags` | string[] (optional) | The assigned minion must have **all** of these tags present in their `tags` array for the reclamation to progress. If the minion lacks any required tag, assignment is blocked (UI shows the requirement). Empty/absent = no tag requirement (tier 1 clutter can be cleared by any minion). |

### Reclamation Gating by Minion Tags

Assignment to a blocked room is a **normal assignment** — the minion occupies a slot in the chamber's `minions` array just as it would for a production room. However, a gating check prevents assignment if the minion does not meet the obstacle's `requires_tags`:

- **Tier 1 (Clutter):** No tag requirement. Any minion can clear clutter.
- **Tier 2 (Rubble):** May require a physical-capability tag (e.g., `"sturdy"`, `"reinforced"`).
- **Tier 3 (Hazards):** May require a resilience tag (e.g., `"scarred"`, `"terrified"` — they won't stop working).
- **Tier 4 (Seals):** May require a specific ally-related or high-level tag.

The exact tags per tier are data-driven in the JSON. The check is: does the minion's `tags` array contain every string in `requires_tags`? If yes, assignment proceeds and nightly clearing begins. If no, the UI prevents the assignment and shows which tags are missing.

### Clearing Progression

Once a valid minion is assigned:
- Each night the minion remains assigned, the obstacle's internal `nights_remaining` counter decrements by 1 (starting from `nights_to_clear`).
- When `nights_remaining` reaches 0, the obstacle is replaced with a buildable slot of the same footprint.
- If the minion is reassigned or terminated before clearing completes, progress is **retained** on the obstacle (it does not reset). A different minion can continue the work.
- The room being reclaimed produces nothing for its guests or minion that night (GDD §10 Reclamation Trade-off).

Obstacle types have no `size` of their own; they occupy whatever footprint their pre-placed layout cell defines.

## obj_chamber Instance Variables

Set at creation (via `instance_create_layer` argument map or post-creation):

| Variable | Type | Source / Notes |
|---|---|---|
| `chamber_type` | string | From blueprint JSON; matches a type definition ID. |
| `chamber_size` | int (ROOM_SIZE enum) | 0=small, 1=medium, 2=large. Derived from the type's `size` field for buildable rooms; taken from layout data for pre-placed obstacles. |
| `grid_x`, `grid_y` | int | Top-left cell position on `mansion_map`. Passed from blueprint layout data. |
| `floor` | FLOOR enum | Derived: `scr_grid_y_to_floor(grid_y)`. |
| `minions` | array of up to `occupancy` instances (`no` = empty slot) | Minions assigned to this chamber (persistent across nights). Capacity comes from the type's optional `occupancy` field, default 1 — single-slot rooms simply hold one entry. Set during Day Phase management; slots stay empty for passive rooms (`requires.minion: false`). Tag/prerequisite checks (`minion_assigned`, `minion_has_tag`) test **any** occupied slot. |
| `clients` | array of up to `client_capacity` instances (`no` = empty slot) | Guests present this night. Capacity comes from the type's optional `client_capacity` field, default 1. Set during Night Phase funnel; reset each cycle (all entries set to `no`). Single-client rooms simply hold one entry. The `requires.client` gate checks for at least one non-`no` entry; `clients_present_count` returns the count of occupied slots. |
| `upgrade_id` | string or `""` | Installed upgrade ID, or empty if none. One per room max. |
| `reclaim_nights_remaining` | int (obstacles only) | Current clearing progress. Initialised to `nights_to_clear` from the type's `reclaim` block. Decrements each night a valid minion is assigned. At 0, the obstacle converts to a buildable slot. |

## Resource Keys (convention)

Resource names used in all JSON maps and the global resource tracker:

- Primary: `"value"`, `"power"`, `"stock"`
- Secondary: `"cash"`, `"lust_mana"`, `"humiliation_mana"`, `"fear_mana"`, `"influence"`

These are string keys in JSON and map keys in GML. A `scr_resource_display_name(key)` helper maps them to player-facing labels ("Lust Mana", "Cash", etc.) for UI rendering. Collectors convert harvested tags into **primary** resources; producers emit **secondary** resources (and carry the tags collectors read).

## Extensibility Notes

- **New room type** → add a JSON entry to the appropriate ally file. No code changes.
- **New upgrade** → add a JSON entry to the appropriate upgrades file. No code changes.
- **New condition type** → add one `case` in `scr_eval_condition`. JSON schema unchanged.
- **New resource type** → add it to the global resource tracker and any relevant JSON cost/effect maps. Existing entries simply don't reference it (absent = 0).
- **New aura/adder room** → add an `aura` map to the type; the nightly-sum aura pass picks it up automatically. No code changes.
- **New reclamation tier** → add an obstacle type with a `reclaim` block including appropriate `requires_tags`. The clearing pipeline reads `tier`/`nights_to_clear`/`requires_tags` generically.
- **New ally** → create `chamber_types/<ally>.json` + `upgrades/<ally>.json`, add both paths to the loader arrays. Calculation engine is agnostic to source.
