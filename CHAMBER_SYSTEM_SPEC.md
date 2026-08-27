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

scripts/
    scr_chamber_types.gml       ← JSON loaders, lookup tables, floor mapping helpers
    scr_chamber_calc.gml        ← evaluation engine (gating, base, bonuses, upgrades, adjacency)

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
  "tags": ["private", "luxury"],
  "requires": { "minion": true, "client": true },
  "cost": { "cash": 50, "lust_mana": 10 },
  "base": { "lust_mana": 5, "value": 5 },
  "bonuses": [ ... ]
}
```

| Field | Type | Purpose |
|---|---|---|
| `type` | string | Unique ID; matches the `chamber_type` variable on the instance and the sprite naming convention. |
| `display_name` | string | Human-readable name for UI. |
| `tags` | string[] | Intrinsic tags carried by this room type (e.g. `"private"`, `"luxury"`, `"dungeon"`). Used in synergy/tag-count calculations. |
| `requires.minion` | bool | If `true`, no production occurs without an assigned minion instance. **All rooms require a minion.** |
| `requires.client` | bool | If `true`, no production occurs without a guest present that night. Most rooms are `true`; utility rooms (Dormitory, Inner Sanctum) are `false`. |
| `cost` | map (resource → int) | Secondary resources spent to build this room. Only list non-zero costs; absent keys cost 0. |
| `base` | map (resource → int) | Flat resource output per night when prerequisites are met. Always applies (no conditions). May be empty `{}` for rooms that only produce via bonuses or abilities. |
| `bonuses` | array of rule objects | Conditional additional outputs (see below). |

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
| `adjacent_room_type` | `room_type` (string or `"*"`), optional `direction` (`"above"`, `"below"`, `"left"`, `"right"`) | bool | Any adjacent chamber matches the given type. |
| `count_tag_on_floor` | `tag` (string), `per` (int, value per match), `max` (int cap) | int | Count of unique chambers on the same floor carrying that tag (including upgrade-added tags). Capped at `max`. |
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
| `tags_added` | string[] of tags appended to the chamber's effective tag list while installed. Affects other rooms' tag-counting bonuses. |

## Effective Tags

A chamber's **effective tags** = its type's intrinsic `tags` + any `tags_added` from its installed upgrade. All tag-based calculations (floor counts, synergy checks) use effective tags, not just base type tags. This means installing Silk Sheets (`tags_added: ["luxury"]`) on a Boudoir makes it count toward a Luxury Studio's floor-luxury bonus.

## Calculation Pipeline

`scr_calculate_chamber(chamber_instance)` executes in order:

1. **Prerequisite gate.** Check `requires.minion` and `requires.client`. If unmet, return immediately with `{ total: {}, lines: [{ detail: reason }], active: false }`. No further evaluation.
2. **Base output.** Add all entries from the type's `base` map to the running total. Record one breakdown line.
3. **Bonus rules.** For each rule in `bonuses[]`: evaluate its condition against the live grid. If triggered, apply `effects` (or `effects_per_match × count`). Record a breakdown line per triggered rule.
4. **Upgrade contribution.** If an upgrade is installed and compatible: add its `effects` to the total. Record a breakdown line.

Return value: `{ total: map, lines: array, active: bool }`.

## Nightly Sum

`scr_calculate_night_earnings()` iterates every cell of `mansion_map`, deduplicates multi-cell rooms via a `ds_set`, calls `scr_calculate_chamber` on each unique instance, and accumulates all `.total` maps into one grand total. Inactive chambers contribute 0.

A variant, `scr_get_night_summary()`, additionally partitions results into `active_rooms[]` and `inactive_rooms[]` (with reasons) for the end-of-cycle "Reckoning" screen.

## Adjacency Logic

Chambers occupy 1×1, 2×1, or 2×2 cells on the grid (per `global.size_dims`). To find neighbours:

1. Determine the subject chamber's bounding box from its `grid_x`, `grid_y`, and size dimensions.
2. Scan all cells in a one-cell ring around that bounding box.
3. Skip cells that fall within the subject's own bounding box.
4. Read each cell from `mansion_map`; skip `-1` (empty) and non-instance values.
5. Deduplicate via `ds_set` (a multi-cell neighbour will appear in multiple ring cells).

This correctly handles all size combinations without special-casing.

## Floor Mapping

The grid is 10 columns × 8 rows. Floor is derived from `grid_y`:

| `grid_y` | Floor |
|---|---|
| 0–1 | Attic (`FLOOR.ATTIC`) |
| 2–3 | First (`FLOOR.FIRST`) |
| 4–5 | Ground (`FLOOR.GROUND`) |
| 6–7 | Basement (`FLOOR.BASEMENT`) |

Two helper functions: `scr_grid_y_to_floor(y)` and `scr_floor_to_grid_rows(floor) → [min, max]`. The floor is computed at instance creation from the passed `grid_y` and stored on the instance.

## obj_chamber Instance Variables

Set at creation (via `instance_create_layer` argument map or post-creation):

| Variable | Type | Source / Notes |
|---|---|---|
| `chamber_type` | string | From blueprint JSON; matches a type definition ID. |
| `chamber_size` | int (ROOM_SIZE enum) | 0=small, 1=medium, 2=large. |
| `grid_x`, `grid_y` | int | Top-left cell position on `mansion_map`. Passed from blueprint layout data. |
| `floor` | FLOOR enum | Derived: `scr_grid_y_to_floor(grid_y)`. |
| `minion` | instance or `no` | Assigned minion (persistent across nights). Set during Day Phase management. |
| `client` | instance or `no` | Guest present this night. Set during Night Phase funnel; reset each cycle. |
| `upgrade_id` | string or `""` | Installed upgrade ID, or empty if none. One per room max. |

## Resource Keys (convention)

Resource names used in all JSON maps and the global resource tracker:

- Primary: `"value"`, `"power"`, `"stock"`
- Secondary: `"cash"`, `"lust_mana"`, `"humiliation_mana"`, `"fear_mana"`, `"influence"`

These are string keys in JSON and map keys in GML. A `scr_resource_display_name(key)` helper maps them to player-facing labels ("Lust Mana", "Cash", etc.) for UI rendering.

## Extensibility Notes

- **New room type** → add a JSON entry to the appropriate ally file. No code changes.
- **New upgrade** → add a JSON entry to the appropriate upgrades file. No code changes.
- **New condition type** → add one `case` in `scr_eval_condition`. JSON schema unchanged.
- **New resource type** → add it to the global resource tracker and any relevant JSON cost/effect maps. Existing entries simply don't reference it (absent = 0).
- **New ally** → create `chamber_types/<ally>.json` + `upgrades/<ally>.json`, add both paths to the loader arrays. Calculation engine is agnostic to source.
