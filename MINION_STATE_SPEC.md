# Minion State System — Technical Specification

## Overview

Minions are converted from guests (or friends) and accumulate tags over time based on which room they are assigned to each night. This system handles:

- **Tag accumulation** — deterministic progression tracks and flat per-night tag application.
- **Recovery** — removal of tags in rest rooms (Dormitory).
- **Terminal actions** — what happens when a minion reaches the end of a progression track (cull, flee, or require restoration).
- **Conversion** — the process by which a guest becomes a minion, including template selection and initial tag setup.
- **Minion upgrades** — data-driven tag-granting purchases available during the Day Phase.
- **Identity & flavour** — naming, backstory, history log, and appearance (sprite) selection.

This system is **separate from** the chamber contribution calculation. It runs as its own pass over all occupied chambers after production resolves. The room-side rules live in the `minion_effects` block of each chamber type definition (see [`CHAMBER_SYSTEM_SPEC.md`](CHAMBER_SYSTEM_SPEC.md)); the processing logic and minion instance state are defined here.

## File Layout

```
datafiles/
    progression_tracks.json         ← named degradation/recovery track definitions
    conversion_templates.json       ← selectable conversion template definitions
    minion_upgrades.json            ← data-driven minion upgrade definitions
    names/
        guest_names.json            ← pool of guest/client names (randomly assigned)
        minion_names.json           ← pool of minion names (player picks from 3 at conversion)
    backstories.json                ← pool of backstory entries (randomly assigned to guests)

scripts/
    scr_minion_state.gml            ← nightly processing: advance tracks, apply tags, handle terminals
    scr_conversion.gml              ← conversion pipeline: template selection, tag setup, history init
    scr_minion_upgrades.gml         ← upgrade purchase/apply logic (Day Phase)

objects/
    obj_minion/                     ← minion instance: holds tag array, progression state, identity
```

## Minion Instance Variables

On each `obj_minion` instance:

| Variable | Type | Purpose |
|---|---|---|
| `tags` | string[] | Flat list of all tags on this minion (e.g. `["experimented", "bionic_hand", "devoted"]`). Order reflects application time (oldest first). All effects are triggered by tag presence, not categorisation. |
| `progression_track_id` | string or `""` | Current progression track the minion is on. Empty if not in a degradation room. |
| `progression_nights` | int | Consecutive nights spent on the current track. Resets when track changes. |
| `progression_step` | int | Index into the track's `steps[]` array of the last step reached. |
| `name` | string | The minion's chosen name (selected from 3 random options at conversion). |
| `guest_name` | string | Original guest name before conversion (retained for reference/flavour). |
| `backstory` | string | Backstory text, copied from the source guest at conversion. |
| `history` | array of strings | Chronological flavour log. First entry is always the conversion narrative. Subsequent entries added by terminal events, upgrades, story beats, and random room-based events. See [History System](#history-system). |
| `sprite_id` | string or sprite index | Current appearance sprite, derived from tag list (see [Appearance](#appearance--sprite-selection)). Updated when tags change. |
| `current_chamber` | instance ref | Back-reference to the chamber this minion is currently assigned to. Set during Day Phase assignment; cleared on terminal. |
| `has_fled` | bool | Set `true` if the minion left via a `flee` terminal action. Used for UI/logic checks before destruction. |

### Tag Model: Single Flat List

All tags — whether they represent degradation, enhancement, quirks, or flavour — live in **one array** (`tags`). There is no positive/negative categorisation at the data level.

- **Effects are triggered by presence.** A separate tag-effects table (out of scope for this spec; will be its own data file or part of a future `tag_effects.json`) maps each tag ID to its mechanical effects. The state system only adds/removes tag strings; it does not interpret their meaning.
- **Context determines value.** A tag like `"experimented"` is negative in the Mad Scientist's Lab context but may be valuable to a client seeking modified subjects. The game does not pre-classify tags as good or bad — the room, the client, and the effects table determine how each tag matters.
- **Quirks are tags.** A minion's quirk (Devoted, Broken, Terrified) is simply a tag added to the `tags` array at conversion time via the chosen conversion template. It persists unless explicitly removed by a later effect.

#### Tag Effects Table (Future Data File)

The mechanical effects each tag grants/penalises will be defined in a separate data-driven table. Examples:

- `"bionic_hand"`: +10% production speed in Lab rooms.
- `"experimented"`: −5 Fear Mana resistance; +2 value when sold to a Mad Scientist client.
- `"scarred"`: Minion cannot be assigned to Luxury-tagged rooms without penalty.
- `"devoted"` (quirk): +1 Lust Mana per night in any room.

This table is **not** part of the state system. The state system writes tags; the effects table and chamber bonus rules read them.

## Conversion Process

Minions are created from guests during **The Hunt** (Night Phase, step 2). The conversion pipeline:

```
The Hunt (conversion):
  1. Player selects a guest to convert.
  2. Player selects a Private-tagged room for the conversion scene.
  3. Player selects ONE conversion template (see below).
  4. Resource cost is paid (Mana + forfeited production, per GDD §7).
  5. Conversion executes:
     a. Guest instance is removed from the active guest pool.
     b. New obj_minion instance is created.
     c. Minion's `tags` array is initialised:
        - Start with any tags the guest carried that are transferable (preference tags, etc.).
        - Apply `tags_to_add` from the chosen template.
        - Remove any tags listed in `tags_to_remove` (if present on the guest).
     d. Minion's `backstory` is copied from the guest.
     e. Minion's `history[0]` is set to a narrative string composed of:
        - The guest's backstory text, followed by
        - A conversion-specific text element from the template (e.g., "Bound in the Mad Scientist's lab, their limbs replaced with clockwork precision.").
     f. Player is presented with 3 randomly selected names from `minion_names.json` and picks one → `name`.
     g. Minion's `sprite_id` is computed from the initial tag list (see Appearance).
     h. The new minion is placed in the room where conversion occurred (the Private room used for The Hunt). This requires that room to have available occupancy (≥ 1 free slot).
  6. Forfeited production: the converted guest generates no Secondary resources this cycle.
```

### Conversion Constraints

- **One template per conversion.** The player picks exactly one; templates are not stackable.
- **Placement:** The new minion is placed in the room where conversion took place. If that room is at full occupancy, the player must free a slot first (or the conversion is blocked — UI should warn).
- **Minion cap:** Minions are converted from guests, so the maximum number of minions equals the guest pool size plus any converted friends. There is no way to exceed this without expanding the pool.
- **No orphans:** Rooms cannot be destroyed once built, so a minion's chamber reference will never dangle due to room removal. The only way a minion loses its room is via terminal actions (cull/flee), which destroy the minion instance itself.

## Conversion Templates

Conversion templates define *how* a guest is transformed — the mechanical and narrative result of the conversion. They are stored in JSON, analogous to room types and upgrades.

**`datafiles/conversion_templates.json`:**

```json
[
  {
    "id": "devoted_soul",
    "display_name": "Devoted Soul",
    "description": "The guest's will is broken and reforged into unwavering loyalty. They serve with eager devotion.",
    "conversion_text": "Their eyes cleared of doubt, replaced by a burning need to please their new mistress.",
    "cost": { "lust_mana": 40 },
    "requires": {
      "rooms_built": [],
      "allies_secured": []
    },
    "tags_to_add": ["devoted", "loyal"],
    "tags_to_remove": ["rebellious", "independent"]
  },
  {
    "id": "broken_vessel",
    "display_name": "Broken Vessel",
    "description": "The guest is shattered — physically or psychologically — and remade as a compliant instrument.",
    "conversion_text": "What was left of their defiance was ground away, leaving only an empty shell that obeys.",
    "cost": { "humiliation_mana": 40 },
    "requires": {
      "rooms_built": ["sex_dungeon"],
      "allies_secured": []
    },
    "tags_to_add": ["broken", "compliant"],
    "tags_to_remove": ["defiant", "proud", "happy"]
  },
  {
    "id": "terrified_thrall",
    "display_name": "Terrified Thrall",
    "description": "The guest is broken by fear. They serve because the alternative is unthinkable.",
    "conversion_text": "A single whispered promise of what waits in the dark was enough. They will never leave.",
    "cost": { "fear_mana": 40 },
    "requires": {
      "rooms_built": [],
      "allies_secured": ["necromancer"]
    },
    "tags_to_add": ["terrified", "subservient"],
    "tags_to_remove": ["brave", "fearless"]
  }
]
```

### Template Schema

| Field | Type | Purpose |
|---|---|---|
| `id` | string | Unique template identifier. |
| `display_name` | string | Player-facing name shown in the conversion UI. |
| `description` | string | Player-facing description of what this conversion does and how it feels. |
| `conversion_text` | string | Narrative fragment appended to the guest's backstory as the first history entry (see Conversion Process step 5e). |
| `cost` | map (resource → int) | Mana/resources required to perform this conversion. Added on top of any room-preference discount (GDD §7 Conversion Cost). |
| `requires.rooms_built` | string[] (optional) | Room type IDs that must exist in the mansion for this template to be available. Empty/absent = no room requirement. |
| `requires.allies_secured` | string[] (optional) | Ally IDs that must have been secured for this template to be available. Empty/absent = no ally requirement. |
| `tags_to_add` | string[] | Tags applied to the new minion's `tags` array at conversion. Typically includes the quirk tag. |
| `tags_to_remove` | string[] | Tags that are removed from the guest's existing tags if present before the new tags are applied. Prevents contradictions (e.g., a "broken" minion shouldn't also be "happy"). |

### Template Availability

A template is **available** to the player during The Hunt if:
1. All `requires.rooms_built` room types exist in the current mansion layout.
2. All `requires.allies_secured` allies have been secured.
3. The player can afford the `cost` (Mana resources).

The conversion UI presents all available templates as selectable options. Only one may be chosen per conversion event.

### Extensibility

- **New template** → add a JSON entry to `conversion_templates.json`. No code changes.
- **New gating criterion** (e.g., requires a specific resource threshold) → extend the `requires` map with a new key and add a check in `scr_conversion.gml`.

## Minion Upgrades

Minion upgrades are data-driven purchases that grant tags to a minion. They are analogous to chamber upgrades but apply to the minion instance rather than a room.

**`datafiles/minion_upgrades.json`:**

```json
[
  {
    "id": "reinforced_spine",
    "display_name": "Reinforced Spine",
    "description": "A titanium spinal implant. The minion can endure more degradation before reaching terminal.",
    "cost": { "cash": 30, "fear_mana": 10 },
    "tags_granted": ["reinforced"],
    "requires_tags": [],
    "requires_rooms": ["basic_lab"],
    "compatible_quirks": []
  },
  {
    "id": "gilded_chains",
    "display_name": "Gilded Chains",
    "description": "Ornate shackles that mark the minion as property of the house. Clients pay a premium.",
    "cost": { "cash": 50, "lust_mana": 15 },
    "tags_granted": ["chained", "displayed"],
    "requires_tags": ["broken"],
    "requires_rooms": [],
    "compatible_quirks": ["broken"]
  }
]
```

### Upgrade Schema

| Field | Type | Purpose |
|---|---|---|
| `id` | string | Unique upgrade identifier. Stored on the minion instance (e.g., in a `upgrades_purchased` array to prevent re-purchase). |
| `display_name` | string | UI text. |
| `description` | string | Player-facing description of what the upgrade does. |
| `cost` | map (resource → int) | Resources spent to purchase this upgrade. Checked against current player resources at purchase time. |
| `tags_granted` | string[] | Tags added to the minion's `tags` array upon purchase. This is the primary mechanical effect for now; specific non-tag effects may be added later. |
| `requires_tags` | string[] (optional) | The minion must have ALL of these tags already present to make this upgrade available. Empty/absent = no tag requirement. |
| `requires_rooms` | string[] (optional) | Room type IDs that must exist in the mansion for this upgrade to be available. Empty/absent = no room requirement. |
| `compatible_quirks` | string[] (optional) | If non-empty, the minion's quirk tag must be one of these values. Empty/absent = compatible with any quirk. |

### Purchase Rules

- **Timing:** Minion upgrades can be purchased at **any point during the Day Phase**, as long as the player has sufficient resources remaining (after any building purchases already made that day).
- **One per minion per upgrade ID.** A minion cannot purchase the same upgrade twice. Tracked via an `upgrades_purchased` string array on the minion instance.
- **First pass — simple list:** The Day Phase UI presents a scrollable list of all available upgrades (filtered by `requires_tags`, `requires_rooms`, `compatible_quirks`, and not-yet-purchased). A draft/pick mechanic is planned for a later stage.
- **Effect:** On purchase, deduct cost, push `tags_granted` into the minion's `tags` array, record in `upgrades_purchased`, append a history entry (see History System), and recompute `sprite_id`.

### Extensibility

- **New upgrade** → add a JSON entry to `minion_upgrades.json`. No code changes.
- **Specific effects beyond tags** → extend the schema with an optional `effects` map (similar to chamber upgrades) and handle in `scr_minion_upgrades.gml`. The tag-granting behaviour remains as the default/simple case.
- **Draft mechanic** → replace the flat list UI with a pick-N-of-M selection. Data schema unchanged; only the presentation/selection logic changes.

## History System

Each minion carries a `history` array of string entries — a chronological flavour log that gives the player narrative context for what has happened to their minions.

### Entry Sources

History entries are appended by:

| Trigger | Example Entry |
|---|---|
| **Conversion** (always first) | "*Backstory text.* Bound in the Mad Scientist's lab, their limbs replaced with clockwork precision." |
| **Terminal event** | "After ten nights of experimentation, Subject 7 finally collapsed. The doctor called it a success." |
| **Minion upgrade purchased** | "Fitted with a reinforced titanium spine. They no longer flinch when the saw comes out." |
| **Story beat / narrative event** | "The Cult Leader visited and whispered something in their ear. They haven't slept since." |
| **Random room-based assignment** | "They found a torn photograph in the dormitory walls. They keep it under their pillow now." |

### Rules

- Entries are **flavour only.** They have no mechanical effect. If a narrative moment needs to trigger a game effect, that effect is driven by a tag (added/removed at the same time as the history entry).
- The array grows over time; there is no cap for now (minion lifespans are bounded by progression tracks and the season structure).
- The first entry (`history[0]`) is always the conversion narrative (backstory + `conversion_text`).
- Random room-based entries: each night, a small probability check per occupied room may append a flavour line. The specific text is drawn from a pool associated with that room type (data-driven; exact pool structure TBD — likely a `history_flavour` array on the chamber type definition or a separate JSON).

## Naming

### Guest Names

- Stored in **`datafiles/names/guest_names.json`** as a flat string array.
- When the guest pool is generated at playthrough start, each guest is assigned a random name from this list (no duplicates within a single pool — sample without replacement).
- The name is displayed in the Funnel, client cards, and conversion UI.

```json
["Margaret", "Dorothy", "Harold", "Linda", "Gerald", "Susan", ...]
```

### Minion Names

- Stored in **`datafiles/names/minion_names.json`** as a flat string array.
- At conversion time, the player is presented with **3 randomly selected names** from this pool and picks one. The chosen name becomes `minion.name`.
- The original guest name is preserved as `minion.guest_name` for reference (e.g., shown in tooltips or history context: "Formerly known as Margaret").
- Names are not consumed from the pool — multiple minions can share a name if the random selection overlaps (unlikely with a sufficiently large pool, but not mechanically prevented).

```json
["Ash", "Rook", "Sable", "Vex", "Marrow", "Lash", "Wren", ...]
```

## Appearance / Sprite Selection

A minion's visual appearance is determined by their current tag list.

- A selection of available sprites is defined (asset-side; exact count and naming convention TBD with art).
- At any time the tag list changes (conversion, nightly tags, upgrade purchase, recovery removal), `sprite_id` is recomputed:
  1. Evaluate the minion's `tags` array against a sprite-selection rule set.
  2. The rule set maps tag combinations to specific sprites (e.g., has `"bionic_hand"` → cybernetic arm overlay; has `"scarred"` + `"experimented"` → heavily modified body type).
  3. If no specific rule matches, fall back to a default sprite for the minion's quirk.
- The exact selection algorithm (priority ordering, layering vs. full-swap, etc.) is an art/presentation concern and will be detailed when sprites are in production. The data hook is: **tag list → sprite ID**.

## Backstories

- Stored in **`datafiles/backstories.json`** as a flat array of string entries (or objects with `id` + `text` if metadata is needed later).
- When the guest pool is generated, each guest is assigned a random backstory from this list (sample without replacement, same as names).
- The backstory has **no base mechanical effect** — it is pure flavour that gives the player story material.
- At conversion, the guest's backstory is copied to `minion.backstory` and forms the first part of `history[0]` (see Conversion Process step 5e).

```json
[
  "A parish vicar who came looking for salvation and found something else entirely.",
  "The town sheriff's wife. She tells herself it's only for the money.",
  "A college professor researching the mansion's history. The research is going poorly.",
  ...
]
```

## Progression Tracks (Data)

**`datafiles/progression_tracks.json`:**

```json
[
  {
    "id": "mad_scientist",
    "display_name": "Scientific Degradation",
    "steps": [
      { "nights": 1,  "tag_applied": "experimented" },
      { "nights": 3,  "tag_applied": "degraded" },
      { "nights": 6,  "tag_applied": "scarred" },
      { "nights": 10, "terminal": true }
    ]
  },
  {
    "id": "necromancer",
    "display_name": "Thralldom Decay",
    "steps": [
      { "nights": 2,  "tag_applied": "withered" },
      { "nights": 5,  "tag_applied": "crumbling" },
      { "nights": 8,  "terminal": true }
    ]
  },
  {
    "id": "cult_leader",
    "display_name": "Zealot Burnout",
    "steps": [
      { "nights": 3,  "tag_applied": "fanatical" },
      { "nights": 7,  "tag_applied": "burnout" },
      { "nights": 10, "terminal": true }
    ]
  },
  {
    "id": "aliens",
    "display_name": "Specimen Degradation",
    "steps": [
      { "nights": 4,  "tag_applied": "abducted_stress" },
      { "nights": 8,  "tag_applied": "consumed" },
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
| `tag_applied` | string (optional) | Tag added to the minion's `tags` array when this step is reached. Mutually exclusive with `terminal`. |
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
    { "tag": "experimented",   "chance": 1.0 },
    { "tag": "bionic_hand",    "max_stacks": 1, "chance": 0.25 }
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
| `tag` | string | Tag ID to apply (pushed onto the minion's `tags` array). |
| `chance` | float (optional) | Probability of application per night (0.0–1.0). Default: 1.0 (always applies). |
| `max_stacks` | int (optional) | Maximum number of times this tag can appear in the minion's `tags` array. If already at max, skip. |

### Recovery Model

```json
"minion_effects": {
  "recovery": {
    "remove_per_night": 1,
    "add_positive_on_upgrade": true
  }
}
```

| Field | Type | Purpose |
|---|---|---|
| `recovery.remove_per_night` | int | Number of tags removed per night from the minion's `tags` array (oldest first, i.e., lowest index). The room does not discriminate by tag type — it simply strips the oldest entries. |
| `recovery.add_positive_on_upgrade` | bool (optional) | If `true`, the room's upgrades can grant additional tags on top of recovery. (Design hook for future Dormitory upgrades.) |

A room uses **one** sub-model or the other, not both. The processor checks for `recovery` first; if present, it applies recovery and skips progression/flat-tag logic.

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
            
            // Only process chambers with an assigned minion AND a minion_effects block.
            // Collect the occupied slots (multi-occupancy rooms iterate each independently).
            var _assigned = [];
            for (var s = 0; s < array_length(_chamber.minions); s++) {
                if (_chamber.minions[s] != no && is_instance(_chamber.minions[s])) {
                    array_push(_assigned, _chamber.minions[s]);
                }
            }
            if (array_length(_assigned) == 0) continue;
            
            var _type_def = scr_get_chamber_type(_chamber.chamber_type);
            if (_type_def == undefined) continue;
            if (!map_exists(_type_def, "minion_effects")) continue;
            var _effects = _type_def.minion_effects;
            
            // Apply the room's effects independently to EACH assigned minion.
            for (var m = 0; m < array_length(_assigned); m++) {
                var _minion = _assigned[m];
                
                // --- Recovery rooms (Dormitory, etc.) ---
                if (map_exists(_effects, "recovery")) {
                    scr_apply_recovery(_minion, _effects.recovery);
                    continue;  // recovery rooms do not also apply degradation
                }
                
                // --- Nerd protection check ---
                if (scr_is_nerd_protected(_minion)) {
                    continue;  // skip all tag application for this minion this night
                }
                
                // --- Progression track advancement ---
                if (map_exists(_effects, "progression_track")) {
                    var _terminated = scr_advance_progression(_minion, _effects);
                    if (_terminated) continue;  // minion is gone; skip flat tags for this one
                }
                
                // --- Flat per-night tags ---
                if (map_exists(_effects, "tags_per_night")) {
                    scr_apply_flat_tags(_minion, _effects.tags_per_night);
                }
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
            array_push(_minion.tags, _step.tag_applied);
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
            var _count = 0;
            for (var j = 0; j < array_length(_minion.tags); j++) {
                if (_minion.tags[j] == _entry.tag) _count++;
            }
            if (_count >= _entry.max_stacks) continue;
        }
        
        array_push(_minion.tags, _entry.tag);
    }
}
```

#### `scr_apply_recovery(minion, recovery_data)`

```gml
function scr_apply_recovery(_minion, _recovery_data) {
    var _to_remove = _recovery_data.remove_per_night;
    
    repeat(_to_remove) {
        if (array_length(_minion.tags) > 0) {
            // Remove oldest tag (index 0)
            array_delete(_minion.tags, 0, 1);
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
                var _chamber = _minion.current_chamber;
                if (_chamber != no && is_instance(_chamber)) {
                    scr_remove_minion_from_chamber(_chamber, _minion);
                }
                instance_destroy(_minion);
            }
            break;
        
        case "flee":
            // Minion leaves the mansion. Remove from chamber, mark as gone.
            if (is_instance(_minion)) {
                var _chamber = _minion.current_chamber;
                if (_chamber != no && is_instance(_chamber)) {
                    scr_remove_minion_from_chamber(_chamber, _minion);
                }
                _minion.has_fled = true;
                instance_destroy(_minion);
            }
            break;
        
        case "restore_cost":
            // Minion survives but requires a resource payment to continue serving.
            var _cost = global.terminal_restore_cost;  // e.g. { cash: 50 }
            if (scr_can_afford(_cost)) {
                scr_pay_cost(_cost);
                // Clear tags as a "restoration" and reset progression
                _minion.tags = [];
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

#### `scr_remove_minion_from_chamber(chamber, minion)`

Helper to remove a specific minion from a chamber's `minions` array (used by terminal actions and reassignment):

```gml
function scr_remove_minion_from_chamber(_chamber, _minion) {
    for (var i = 0; i < array_length(_chamber.minions); i++) {
        if (_chamber.minions[i] == _minion) {
            _chamber.minions[i] = no;
            return;
        }
    }
}
```

## Design Rules & Constraints

| Rule | Detail |
|---|---|
| **No roaming minions** | Every minion must be assigned to a room at all times. There is no "unassigned" or "roaming" state. If a player has no productive task for a minion, they assign it to a Dormitory (recovery) or a reclamation obstacle. This prevents accidental bottlenecks where minions sit idle with no purpose. |
| **Minion cap** | Max minions = guest pool size + converted friends. Minions are only created via conversion; there is no other source. The fixed guest pool (GDD §7) bounds this naturally. |
| **No orphan handling needed** | Rooms cannot be destroyed once built. A minion's `current_chamber` reference will never dangle due to room removal. Terminal actions destroy the minion instance itself, cleaning up the chamber slot. |
| **Placement on conversion** | The newly converted minion is placed in the room where The Hunt occurred (the Private-tagged room used for conversion). This requires an available occupancy slot in that room. |
| **One template per conversion** | A single conversion event uses exactly one template. Templates are not stackable or combinable. |

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
- Calculation logic. Production doesn't read minion tags for its core calculation; state changes don't produce resources.
- Failure modes. A room producing 0 is a non-event; a minion dying is a game event with UI feedback.

### Natural Interaction: Terminal → Inactive Room

When a minion is culled/flees, the chamber's slot is set to `no`. On subsequent nights, that chamber may fail its `requires.minion` gate (if no other minions occupy it) and produce nothing until a replacement is assigned. No special handling needed — it falls out of the existing prerequisite check.

### Natural Interaction: Tags → Production Bonuses

Minion tags can influence production via the `minion_has_tag` condition type in bonus rules (defined in the chamber spec). Example: a Boudoir with a bonus rule `{ "condition": { "type": "minion_has_tag", "tag": "devoted" }, "effects": { "lust_mana": 2 } }`. The production system reads minion tags; the state system writes them. They communicate through the minion instance's `tags` array.

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
- **New tag with gameplay effects** → define the effect in the tag-effects table (separate concern). The state system only adds/removes tag strings; it doesn't interpret their mechanical meaning.
- **Recovery upgrades** → extend the `recovery` sub-model with additional fields (e.g., `remove_per_night: 2`, or `heal_progression_steps: 1`). Add handling in `scr_apply_recovery`.
- **Multiple progression tracks per room** → not currently supported. If needed, change `progression_track` from a string to an array and advance all referenced tracks simultaneously (or pick the most severe). Unlikely to be needed given one-upgrade-per-room constraint.
- **New conversion template** → add a JSON entry to `conversion_templates.json`. No code changes.
- **New minion upgrade** → add a JSON entry to `minion_upgrades.json`. No code changes.
- **Tag categorisation (future)** → if tags later need categories (e.g., for UI filtering or targeted removal), add a `category` field to the tag-effects data file. The minion instance's flat `tags` array remains unchanged; categorisation is a lookup concern, not a storage concern.
- **Draft mechanic for upgrades** → replace the flat list UI with a pick-N-of-M selection flow. Data schema unchanged.
