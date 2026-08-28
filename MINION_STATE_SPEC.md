# Minion State System — Technical Specification

## Overview

Minions accumulate tags over time based on which room they are assigned to each night. This system handles:

- **Progression tracks** — deterministic, per-night degradation sequences (e.g., experimented → degraded → scarred → terminal).
- **Flat tag application** — probabilistic or guaranteed tags added/removed each night independent of progression.
- **Recovery** — removal of negative tags in rest rooms (Dormitory).
- **Terminal actions** — what happens when a minion reaches the end of a progression track (cull, flee, or require restoration).

This system is **separate from** the chamber contribution calculation. It runs as its own pass over all occupied chambers after production resolves. The room-side rules live in the `minion_effects` block of each chamber type definition (see [`CHAMBER_SYSTEM_SPEC.md`](CHAMBER_SYSTEM_SPEC.md)); the processing logic and minion instance state are defined here.

## File Layout

```
datafiles/
    progression_tracks.json     ← named degradation/recovery track definitions

scripts/
    scr_minion_state.gml        ← nightly processing: advance tracks, apply tags, handle terminals

objects/
    obj_minion/                 ← minion instance: holds tag arrays, progression state
```

## Progression Tracks (Data)

**`datafiles/progression_tracks.json`:**

```json
[
  {
    "id": "mad_scientist",
    "display_name": "Scientific Degradation",
    "steps": [
      { "nights": 1,  "tag_applied": "experimented", "polarity": "negative" },
      { "nights": 3,  "tag_applied": "degraded",     "polarity": "negative" },
      { "nights": 6,  "tag_applied": "scarred",      "polarity": "negative" },
      { "nights": 10, "terminal": true }
    ]
  },
  {
    "id": "necromancer",
    "display_name": "Thralldom Decay",
    "steps": [
      { "nights": 2,  "tag_applied": "withered",   "polarity": "negative" },
      { "nights": 5,  "tag_applied": "crumbling",  "polarity": "negative" },
      { "nights": 8,  "terminal": true }
    ]
  },
  {
    "id": "cult_leader",
    "display_name": "Zealot Burnout",
    "steps": [
      { "nights": 3,  "tag_applied": "fanatical",      "polarity": "negative" },
      { "nights": 7,  "tag_applied": "burnout",        "polarity": "negative" },
      { "nights": 10, "terminal": true }
    ]
  },
  {
    "id": "aliens",
    "display_name": "Specimen Degradation",
    "steps": [
      { "nights": 4,  "tag_applied": "abducted_stress", "polarity": "negative" },
      { "nights": 8,  "tag_applied": "consumed",        "polarity": "negative" },
      { "nights": 12, "terminal": true }
    ]
  }
]
```

### Track Schema

| Field | Type | Purpose |
|---|---|---|
| `id` | string | Unique track identifier. Referenced by `minion_effects.progression_track` in chamber type definitions. |
| `display_name` | string | Player-facing name for UI (e.g., shown on minion status panel). |
| `steps` | array | Ordered list of progression milestones. |

### Step Schema

| Field | Type | Purpose |
|---|---|---|
| `nights` | int | Cumulative night count at which this step triggers (not a per-step duration). Must be in ascending order. |
| `tag_applied` | string (optional) | Tag added to the minion when this step is reached. Mutually exclusive with `terminal`. |
| `polarity` | string (optional) | `"positive"` or `"negative"`. Determines which tag array receives the tag. Default: `"negative"`. |
| `terminal` | bool (optional) | If `true`, this step is the final one — the minion is lost via the room's `terminal_action`. No further steps exist after this. |

### Track Reset Rules

- The night counter resets to 0 when a minion is moved to a room with a **different** progression track (or no track).
- The night counter **does not** reset if the minion stays in the same track across consecutive nights, even if moved between two rooms that share the same track.
- Recovery (Dormitory) does **not** reduce the progression counter — it only removes tags. A minion at step 3 who spends a night in the Dormitory is still at step 3 when returned to the Lab.

## Room-Side: `minion_effects` Block

Defined on chamber types (full context in [`CHAMBER_SYSTEM_SPEC.md`](CHAMBER_SYSTEM_SPEC.md)). Two mutually exclusive sub-models:

### Degradation / Progression Model

```json
"minion_effects": {
  "progression_track": "mad_scientist",
  "tags_per_night": [
    { "tag": "experimented",   "polarity": "negative" },
    { "tag": "bionic_hand",    "polarity": "positive", "max_stacks": 1, "chance": 0.25 }
  ],
  "terminal_action": "cull"
}
```

| Field | Type | Purpose |
|---|---|---|
| `progression_track` | string (optional) | ID of a progression track to advance each night. Omit if the room only applies flat tags without a structured sequence. |
| `tags_per_night` | array (optional) | Flat tags applied every night the minion is in this room. Independent of progression steps. |
| `terminal_action` | string (required if `progression_track` present) | What happens at terminal: `"cull"`, `"flee"`, or `"restore_cost"`. |

#### `tags_per_night` Entry Schema

| Field | Type | Purpose |
|---|---|---|
| `tag` | string | Tag ID to apply. |
| `polarity` | string | `"positive"` or `"negative"`. |
| `chance` | float (optional) | Probability of application per night (0.0–1.0). Default: 1.0 (always applies). |
| `max_stacks` | int (optional) | Maximum number of times this tag can appear on the minion. If already at max, skip. |

### Recovery Model

```json
"minion_effects": {
  "recovery": {
    "remove_negative_per_night": 1,
    "add_positive_on_upgrade": true
  }
}
```

| Field | Type | Purpose |
|---|---|---|
| `recovery.remove_negative_per_night` | int | Number of negative tags removed per night (oldest first). |
| `recovery.add_positive_on_upgrade` | bool (optional) | If `true`, the room's upgrades can grant positive tags on top of recovery. (Design hook for future Dormitory upgrades.) |

A room uses **one** sub-model or the other, not both. The processor checks for `recovery` first; if present, it applies recovery and skips progression/flat-tag logic.

## Minion Instance Variables

On each `obj_minion` instance:

| Variable | Type | Purpose |
|---|---|---|
| `tags_positive` | string[] | Accumulated positive tags (e.g. `["bionic_hand", "devoted"]`). |
| `tags_negative` | string[] | Accumulated negative tags (e.g. `["experimented", "traumatised"]`). |
| `progression_track_id` | string or `""` | Current progression track the minion is on. Empty if not in a degradation room. |
| `progression_nights` | int | Consecutive nights spent on the current track. Resets when track changes. |
| `progression_step` | int | Index into the track's `steps[]` array of the last step reached. |

### Tag Polarity & Gameplay Effects

Tags are flavour + mechanical modifiers. The specific effects each tag grants/penalises are defined in a separate tag-effects table (out of scope for this spec; will be its own data file or part of the minion definition). Examples:

- `"bionic_hand"` (positive): +10% production speed in Lab rooms.
- `"experimented"` (negative): −5 Fear Mana resistance.
- `"scarred"` (negative): Minion cannot be assigned to Luxury-tagged rooms without penalty.
- `"devoted"` (positive, from conversion): +1 Lust Mana per night in any room.

## Nightly Processing Pipeline

Runs as **step 4** of the Night Phase (after production, before Reckoning):

```
Night Phase:
  1. Funnel — assign clients to chambers
  2. The Hunt — player converts a guest (optional)
  3. Production — scr_calculate_night_earnings() → apply resources
  4. State Changes — scr_process_minion_states() → tags, progression, terminals  ← THIS SYSTEM
  5. Reckoning — check achievements, build next night's visitor list
```

### Entry Point

```gml
/// @description Process minion state changes for all occupied chambers.
function scr_process_minion_states() {
    var _seen = ds_set_create();
    
    var _w = ds_grid_width(mansion_map);
    var _h = ds_grid_height(mansion_map);
    
    for (var x = 0; x < _w; x++) {
        for (var y = 0; y < _h; y++) {
            var _chamber = ds_grid_get(mansion_map, x, y);
            if (_chamber == -1 || !is_instance(_chamber)) continue;
            if (ds_set_find(_seen, _chamber) != -1) continue;
            ds_set_add(_seen, _chamber);
            
            // Only process chambers with an assigned minion AND a minion_effects block
            if (_chamber.minion == no || !is_instance(_chamber.minion)) continue;
            
            var _type_def = scr_get_chamber_type(_chamber.chamber_type);
            if (_type_def == undefined) continue;
            if (!map_exists(_type_def, "minion_effects")) continue;
            
            var _effects = _type_def.minion_effects;
            var _minion  = _chamber.minion;
            
            // --- Recovery rooms (Dormitory, etc.) ---
            if (map_exists(_effects, "recovery")) {
                scr_apply_recovery(_minion, _effects.recovery);
                continue;  // recovery rooms do not also apply degradation
            }
            
            // --- Progression track advancement ---
            if (map_exists(_effects, "progression_track")) {
                var _terminated = scr_advance_progression(_minion, _effects);
                if (_terminated) continue;  // minion is gone; skip flat tags
            }
            
            // --- Flat per-night tags ---
            if (map_exists(_effects, "tags_per_night")) {
                scr_apply_flat_tags(_minion, _effects.tags_per_night);
            }
        }
    }
    
    ds_set_destroy(_seen);
}
```

### Sub-Functions

#### `scr_advance_progression(minion, room_effects) → bool`

Returns `true` if the minion was terminated (caller should skip further processing).

```gml
function scr_advance_progression(_minion, _room_effects) {
    var _track_id = _room_effects.progression_track;
    
    // Reset counter if track changed
    if (_minion.progression_track_id != _track_id) {
        _minion.progression_track_id = _track_id;
        _minion.progression_nights   = 0;
        _minion.progression_step     = 0;
    }
    
    _minion.progression_nights++;
    
    var _track = scr_get_progression_track(_track_id);
    if (_track == undefined) return false;
    
    // Advance through any steps whose threshold has been met
    while (_minion.progression_step < array_length(_track.steps)
           && _minion.progression_nights >= _track.steps[_minion.progression_step].nights) {
        
        var _step = _track.steps[_minion.progression_step];
        
        // Terminal step?
        if (map_exists(_step, "terminal") && _step.terminal) {
            scr_handle_minion_terminal(_minion, _room_effects.terminal_action);
            return true;
        }
        
        // Apply tag
        if (map_exists(_step, "tag_applied")) {
            var _polarity = map_exists(_step, "polarity") && _step.polarity == "positive"
                           ? "tags_positive" : "tags_negative";
            array_push(_minion[_polarity], _step.tag_applied);
        }
        
        _minion.progression_step++;
    }
    
    return false;
}
```

#### `scr_apply_flat_tags(minion, tag_list)`

```gml
function scr_apply_flat_tags(_minion, _tag_list) {
    for (var i = 0; i < array_length(_tag_list); i++) {
        var _entry = _tag_list[i];
        
        // Chance check (default 1.0)
        var _chance = map_exists(_entry, "chance") ? _entry.chance : 1.0;
        if (random(1.0) > _chance) continue;
        
        // Stack limit
        if (map_exists(_entry, "max_stacks")) {
            var _polarity = _entry.polarity == "positive" ? "tags_positive" : "tags_negative";
            var _count = 0;
            for (var j = 0; j < array_length(_minion[_polarity]); j++) {
                if (_minion[_polarity][j] == _entry.tag) _count++;
            }
            if (_count >= _entry.max_stacks) continue;
        }
        
        var _polarity = _entry.polarity == "positive" ? "tags_positive" : "tags_negative";
        array_push(_minion[_polarity], _entry.tag);
    }
}
```

#### `scr_apply_recovery(minion, recovery_data)`

```gml
function scr_apply_recovery(_minion, _recovery_data) {
    var _to_remove = _recovery_data.remove_negative_per_night;
    
    repeat(_to_remove) {
        if (array_length(_minion.tags_negative) > 0) {
            // Remove oldest negative tag (index 0)
            array_delete(_minion.tags_negative, 0, 1);
        }
    }
}
```

#### `scr_handle_minion_terminal(minion, action)`

```gml
function scr_handle_minion_terminal(_minion, _action) {
    switch (_action) {
        case "cull":
            // Minion is destroyed. Remove from chamber, free the slot.
            if (is_instance(_minion)) {
                var _chamber = _minion.current_chamber;  // back-reference
                if (_chamber != no && is_instance(_chamber)) {
                    _chamber.minion = no;
                }
                instance_destroy(_minion);
            }
            break;
        
        case "flee":
            // Minion leaves the mansion. Remove from chamber, mark as gone.
            if (is_instance(_minion)) {
                var _chamber = _minion.current_chamber;
                if (_chamber != no && is_instance(_chamber)) {
                    _chamber.minion = no;
                }
                _minion.has_fled = true;
                instance_destroy(_minion);
            }
            break;
        
        case "restore_cost":
            // Minion survives but requires a resource payment to continue serving.
            // Deduct from player resources; if unaffordable, treat as "flee".
            var _cost = global.terminal_restore_cost;  // e.g. { cash: 50 }
            if (scr_can_afford(_cost)) {
                scr_pay_cost(_cost);
                // Clear negative tags as a "restoration"
                _minion.tags_negative = [];
                _minion.progression_nights = 0;
                _minion.progression_step   = 0;
            } else {
                // Can't afford restoration — minion flees
                scr_handle_minion_terminal(_minion, "flee");
            }
            break;
    }
}
```

## Interaction with Chamber Contribution System

The two systems are **independent passes** over the same grid:

| Pass | Script | Concern |
|---|---|---|
| Production (step 3) | `scr_calculate_night_earnings()` | What resources does each room produce? Gated by minion/client presence. |
| State Changes (step 4) | `scr_process_minion_states()` | How do rooms modify the minions inside them? |

They share:
- The same grid iteration + dedup pattern.
- The same chamber type definitions (the `minion_effects` block lives in the same JSON as `base`, `bonuses`, etc.).

They do **not** share:
- Calculation logic. Production doesn't read minion tags; state changes don't produce resources.
- Failure modes. A room producing 0 is a non-event; a minion dying is a game event with UI feedback.

### Natural Interaction: Terminal → Inactive Room

When a minion is culled/flees, the chamber's `minion` reference is set to `no`. On subsequent nights, that chamber fails its `requires.minion` gate and produces nothing until a replacement is assigned. No special handling needed — it falls out of the existing prerequisite check.

### Natural Interaction: Tags → Production Bonuses

Minion tags can influence production via the `minion_has_tag` condition type in bonus rules (defined in the chamber spec). Example: a Boudoir with a bonus rule `{ "condition": { "type": "minion_has_tag", "tag": "devoted" }, "effects": { "lust_mana": 2 } }`. The production system reads minion tags; the state system writes them. They communicate through the minion instance's tag arrays.

## Nerd Exception (GDD §5)

The Nerd friend archetype halts all tag accumulation for herself and any minion sharing her room. Implementation:

In `scr_process_minion_states`, before applying degradation to a minion, check if that minion (or the chamber it's in) is co-located with an active Nerd instance:

```gml
// In the processing loop, before scr_advance_progression / scr_apply_flat_tags:
if (scr_is_nerd_protected(_minion)) {
    continue;  // skip all tag application for this minion this night
}
```

`scr_is_nerd_protected(minion)` checks whether the minion's current chamber is the same as a Nerd minion's chamber, or whether the Nerd IS the minion in question. Recovery (Dormitory) still applies — the Nerd prevents *accumulation*, not *recovery*.

## Extensibility Notes

- **New progression track** → add an entry to `progression_tracks.json`. No code changes.
- **New terminal action** → add a `case` in `scr_handle_minion_terminal`. JSON schema unchanged (it's just a string).
- **New tag with gameplay effects** → define the effect in the minion tag-effects table (separate concern). The state system only adds/removes tag strings; it doesn't interpret their mechanical meaning.
- **Recovery upgrades** → extend the `recovery` sub-model with additional fields (e.g., `remove_negative_per_night: 2`, or `heal_progression_steps: 1`). Add handling in `scr_apply_recovery`.
- **Multiple progression tracks per room** → not currently supported. If needed, change `progression_track` from a string to an array and advance all referenced tracks simultaneously (or pick the most severe). Unlikely to be needed given one-upgrade-per-room constraint.
