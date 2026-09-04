# Minion System — Technical Specification

This spec defines **one** minion system: identity, tags, conversion, room assignment, reclamation gating, upgrades, appearance, backstory and history. It supersedes `MINION_STATE_SPEC.md`, which is retired — its nightly tag-status pipeline (progression tracks, cull/flee/restore) is preserved as a designed-but-deferred mechanic in [`FUTURE_FEATURES.md`](FUTURE_FEATURES.md).

Companion specs:
- [`CHAMBER_SYSTEM_SPEC.md`](CHAMBER_SYSTEM_SPEC.md) — room side (`minions[]` array, `occupancy`, reclamation obstacles, bonus conditions like `minion_has_tag`).
- [`CLIENT_SYSTEM_SPEC.md`](CLIENT_SYSTEM_SPEC.md) — guests/clients, the source of most minions.
- [`Game-Design-Document.md`](Game-Design-Document.md) — design intent (§5 Friends, §7 Minions, §10 Reclamation).

## Overview

Minions are named servant instances in `obj_minion`. They:

- Are created by **conversion** of a guest (or via scripted friend events), carrying over the guest's tags and backstory.
- Carry a **single flat tag array**. Tags have no polarity; good/bad depends on context — the room they're in or the client they serve. Effects are triggered purely by tag *presence*.
- Are **always assigned to exactly one chamber** (no roaming). New minions default into the chamber where they were converted.
- Can be assigned to **reclamation obstacles**; a gate checks whether their tags let them clear it.
- Have **one upgrade slot**, purchasable at any time during the day phase; upgrades grant tags for now (data-driven, gated like chamber upgrades).
- Have an **appearance** derived from their tag list.
- Keep a **history** of flavour line items: conversion, terminal events, upgrades, story beats, and random room-flavoured entries.

Design invariant: **tags are the only mechanical surface.** Anything that needs to be meaningful (production bonuses, reclamation capability, future status effects) is read from or written to the tag array. History and backstory are flavour only.

## File Layout

```
datafiles/
    minion_conversion_templates.json  ← named conversion templates (gate + cost + tags +/-)
    minion_upgrades.json              ← minion upgrade definitions
    backstories.json                  ← guest/minion backstory pool
    client_names.json                 ← guest name pool
    minion_names.json                 ← minion name pool

scripts/
    scr_minions.gml                   ← minion instance creation, conversion, assignment validation
    scr_minion_tags.gml               ← tag add/remove/query helpers (incl. appearance lookup)

objects/
    obj_minion/                       ← minion instance: identity fields + state vars (below)
```

## Minion Instance Variables (`obj_minion`)

| Variable | Type | Purpose |
|---|---|---|
| `minion_id` | int/string | Unique ID (save-system-ready). |
| `name` | string | Display name. Chosen at conversion from 3 random picks drawn from `minion_names.json`; if the player doesn't choose, keeps the guest's name. Friends use their archetype-based names instead. |
| `tags` | string[] | Single flat tag list — identity tags, quirk tag, acquired tags, upgrade-granted tags all live here unclassified (see [Tags](#tags)). |
| `quirk` | string or `""` | Convenience mirror of the conversion template's quirk (`"devoted"`, `"broken"`, `"terrified"`, …). Also present as a tag in `tags`; kept separate for cheap UI/lookup. Friend minions carry their archetype quirk (GDD §5). |
| `backstory` | string | Copied verbatim from the converted guest's backstory. Shown in the minion panel alongside history. |
| `history` | array of `{ cycle: int, text: string }` | Flavour line items, oldest first. Written by conversion (item #1), terminal events, upgrades, story beats, and random room-flavoured entries (see [History](#history)). Never read mechanically. |
| `upgrade_id` | string or `""` | The single installed minion upgrade ID, or empty if none purchased yet. |
| `current_chamber` | instance or `no` | Back-reference to the chamber this minion is assigned to (set during day-phase assignment). `no` only transiently (e.g., between conversion and default placement — which happens immediately). |
| `sprite_id` | sprite ref | Appearance, resolved from `tags` via [Appearance](#appearance). Re-resolved whenever `tags` changes. |
| `is_friend` | bool | `true` for the drafted friend cast (best-friend arc, GDD §5/§8); these skip the 3-pick naming and use authored identity data instead of pool picks. |

### Capacity Note

There is no hard cap on minion count: capacity is limited by room occupancy slots ([multi-occupancy](#room-assignment)). The realistic ceiling is the guest pool size plus converted friends — a minion can only exist if someone was converted (GDD §7 Guest Pool). Rooms cannot currently be destroyed, so orphaned-minion handling is out of scope.

## Tags

**One unclassified array.** No `tags_positive`/`tags_negative`, no polarity field on tags themselves. A tag's valence depends on context:

- `experimented → degraded → scarred → terminal` in the Mad Scientist Lab are *bad*, but a `bionic_hand` from that same room may be highly valuable to the right client (production bonuses via the chamber spec's `minion_has_tag` condition).
- A quirk tag (`devoted`) is mechanically meaningful, not "positive" — it changes mana flavour interactions and conversion cost matching.

### How tags are read/written

| Source | Action | Spec home |
|---|---|---|
| Conversion template | add `tags_added`, remove any present in `tags_removed` | [Conversion](#conversion) below |
| Guest inheritance | copied verbatim at conversion (preference/identity tags persist — a *dominant* client is still *dominant* as a minion, which matters for preference matching and room synergies) | this spec + [`CLIENT_SYSTEM_SPEC.md`](CLIENT_SYSTEM_SPEC.md) |
| Minion upgrades | add `tags_added` on purchase | [Upgrades](#upgrades) below |
| Rooms (per-night effects) | add/remove tags nightly via `minion_effects` in chamber type definitions — **deferred to future features** ([FUTURE_FEATURES.md](FUTURE_FEATURES.md)) until the tag-status pipeline lands | [`CHAMBER_SYSTEM_SPEC.md`](CHAMBER_SYSTEM_SPEC.md) |
| Reclamation gating | reads a required tag-set on obstacles | [Reclamation](#reclamation-assignment-gating) below |
| Appearance resolution | maps `tags` → sprite | [Appearance](#appearance) below |

### Helper contract (`scr_minion_tags.gml`)

```gml
/// @description Add a tag if not already present (no stacks in v1).
function minion_tag_add(_minion, _tag);

/// @description Remove all occurrences of a tag.
function minion_tag_remove(_minion, _tag);

/// @description True if the minion carries every tag in _required (array or single string).
function minion_has_tags(_minion, _required);

/// @description Re-resolve _minion.sprite_id from its tag list and re-sync appearance.
function minion_refresh_appearance(_minion);
```

Any code path that mutates `tags` must call `minion_refresh_appearance()` afterwards so the sprite stays in sync.

## Conversion

Conversion is a **night-phase** action (GDD §2: The Hunt — escort a guest into a Private-tagged room). It produces one new minion and removes one guest; it is *not* an in-place mutation of the guest instance.

### Template Data (`datafiles/minion_conversion_templates.json`)

Templates are named, player-selectable options shown on the conversion screen (same UI treatment as chamber/upgrade lists: display name + description). The player picks **one** template per conversion. A template is selectable only when its gate passes *and* its cost can be paid.

```json
[
  {
    "id": "devotion_ritual",
    "display_name": "Rite of Devotion",
    "description": "Bind them with lust and longing. The resulting minion serves out of love.",
    "cost": { "lust_mana": 40, "sexual_energy": 1 },
    "gate": { "requires_rooms": ["boudoir"], "requires_allies": [] },
    "quirk": "devoted",
    "tags_added": ["devoted", "loyal"],
    "tags_removed": ["defiant", "broken"],
    "text": "Their eyes found you in the dark and never looked away. From this night on, they belong to you — willingly."
  },
  {
    "id": "break_ritual",
    "display_name": "The Breaking",
    "description": "Grind them down until only obedience is left.",
    "cost": { "humiliation_mana": 40, "sexual_energy": 1 },
    "gate": { "requires_rooms": ["sex_dungeon"], "requires_allies": [] },
    "quirk": "broken",
    "tags_added": ["broken", "compliant"],
    "tags_removed": ["defiant", "devoted"],
    "text": "By the time it was over, they couldn't remember their own name. They only knew yours."
  },
  {
    "id": "terror_ritual",
    "display_name": "Whisper in the Walls",
    "description": "Show them what lives beneath the floorboards.",
    "cost": { "fear_mana": 40, "sexual_energy": 1 },
    "gate": { "requires_rooms": [], "requires_allies": [] },
    "quirk": "terrified",
    "tags_added": ["terrified", "obedient"],
    "tags_removed": ["defiant"],
    "text": "They still flinch at shadows now. Yours, mostly."
  }
]
```

### Template Schema

| Field | Type | Purpose |
|---|---|---|
| `id` | string | Unique template identifier. |
| `display_name` | string | Player-facing name in the conversion UI list. |
| `description` | string | One-paragraph blurb shown on hover/selection. |
| `cost` | map | Resources paid at conversion (e.g., `{ "lust_mana": 40, ... }`). Mana flavour drives the quirk per GDD §7. **Separate from** the preference-matching discount and background-knowledge discount in GDD §7 Conversion Cost, which apply on top of this base cost. |
| `gate.requires_rooms` | string[] (optional) | Template is only *shown/selectable* if these chamber types exist built in the mansion. |
| `gate.requires_allies` | string[] (optional) | Template requires these allies secured (e.g., advanced rites unlocked by ally gateways). |
| `quirk` | string | Quirk written to the minion and added as a tag. Drives mana-flavour behaviour and friend-archetype matching. |
| `tags_added` | string[] | Tags applied to the new minion at creation. Includes the quirk tag. |
| `tags_removed` | string[] | Tags removed from the inherited set *if present* — keeps inherited guest tags coherent with the outcome (a *broken* minion shouldn't still be tagged *happy*; a *devoted* one shouldn't keep *defiant*). |
| `text` | string | Authorised conversion paragraph. Becomes **history line item #1** for the new minion. |

Cost/gate numbers above are placeholders to tune; the schema is what matters.

### Conversion Procedure (`scr_minions.gml`)

```
function scr_convert_guest(_guest, _template) -> obj_minion:
    1. Validate gate (rooms/alleys built) and afford `cost`; pay on success.
       The guest's night is forfeited — they generate no resources this cycle (GDD §7).
    2. Draw 3 random names from minion_names.json (no duplicates, excluding
       already-used minion names); present in UI. On selection use that name;
       if the player skips/defaults, keep _guest.name.
    3. Create new obj_minion instance:
         tags        = copy(_guest.tags)
         backstory   = copy of _guest.backstory (verbatim)
         history     = [ { cycle: current_cycle, text: template.text } ]
         quirk       = template.quirk
         is_friend   = false
    4. Apply template.tags_added → minion_tag_add(each).
       Apply template.tags_removed → minion_tag_remove(each).
    5. minion_refresh_appearance().
    6. Default assignment: place the new minion in _guest's current chamber
       (the Private room where conversion happened) if it has free occupancy;
       otherwise fall back to any room with a free slot (day-phase UI can re-assign).
    7. Destroy the guest instance and remove them from the fixed guest pool —
       permanently, per GDD §7 Guest Pool ("every minion gained is income you will never earn again").
```

Friends do **not** go through this pipeline. Best-friend conversion (Spring, scripted Interaction View) and second-friend lure/conversion (Summer) call a shared internal `scr_create_minion(...)` with authored identity data (`is_friend = true`, archetype quirk per GDD §5); the best friend's backstory/history are authored, not pool-drawn.

## Room Assignment

- Every minion is assigned to exactly one chamber at all times; **no roaming/minions-without-a-room in v1**. This prevents accidental bottlenecks (a player who converts a guest with no spare capacity must consciously move someone).
- Chamber side: `obj_chamber.minion` becomes a **minions[] array** with an `occupancy` field on chamber types defaulting to 1. Single-occupancy rooms behave exactly as before; a Dormitory is just `occupancy: N` (see [`CHAMBER_SYSTEM_SPEC.md`](CHAMBER_SYSTEM_SPEC.md)).
- Assignment is free-form during the day phase except for two validation checks in `scr_minions.gml`:

```gml
/// @description True if _minion may be assigned to _chamber.
function scr_can_assign(_minion, _chamber) -> bool {
    // 1. Occupancy: array_length(_chamber.minions) < chamber type's occupancy (default 1).
    // 2. Reclamation gate: if _chamber is an obstacle with a `reclaim` block,
    //    minion_has_tags(_minion, reclaim.requires_tags) must pass — see below.
}

/// @description Assign and maintain both references.
function scr_assign_minion(_minion, _chamber);   // removes from old chamber, pushes into new, sets current_chamber
```

- New minions default to the conversion room (procedure step 6 above) so conversion never strands a minion.

### Dormitories & multi-occupancy

Rest rooms are future-flavoured (tag *recovery* is in [FUTURE_FEATURES.md](FUTURE_FEATURES.md)), but `occupancy > 1` ships now: it's needed the moment any rest/healing room exists, and makes "rest minion X" trivially expressible as an assignment.

## Reclamation Assignment Gating

Reclaiming a blocked zone is **normal chamber assignment** — there is no separate task state on the minion (GDD §10). The obstacle's `reclaim` block in its chamber type definition does all the work, and gates who may be assigned to it:

```json
"reclaim": {
  "tier": 2,
  "nights_to_clear": 3,
  "requires_tags": ["hardened"]
}
```

| Field | Type | Purpose |
|---|---|---|
| `tier` | int | Reclamation tier (1 = Clutter … 4 = Seals). Drives `nights_to_clear` scaling and future tag/upgrade duration modifiers. |
| `nights_to_clear` | int | Base nights to clear once a minion is assigned; tags/upgrades can reduce this later. |
| `requires_tags` | string[] (optional) | A minion may only be **assigned** to this obstacle if it carries *every* tag in the set. Omitted/empty = any minion can attempt it (Clutter). |

Gating is a hard assignment-time check via `scr_can_assign()` — invalid assignments are disallowed in UI, not failed at night resolution. Higher tiers (Rubble → Hazards → Seals) require tags that come from upgrades, conversion templates, or (later) room-granted tags, which is what makes expansion "gated by minion capabilities" per GDD §10 while keeping the mechanic data-driven and trivially extensible.

While a minion is assigned to an obstacle, the obstacle produces nothing that night — it *is* the work (GDD §10 trade-off).

## Upgrades

- **One slot** per minion (`upgrade_id`), purchased at any point during the day phase from the data-driven list, purchasable whenever resources allow.
- Presented as a plain list for the first pass; **draft-style selection is deferred** to [FUTURE_FEATURES.md](FUTURE_FEATURES.md).
- In v1 upgrades **grant tags only** (plus flavour); specific numeric effects are a future feature. Because production bonuses already read `minion_has_tag` on the chamber side, tag-granting upgrades compose with existing rooms without new code.

### Upgrade Data (`datafiles/minion_upgrades.json`)

```json
[
  {
    "id": "hardened_hide",
    "display_name": "Hardened Hide",
    "description": "Season in the work of the house until it stops mattering.",
    "compatible_types": ["minion"],
    "cost": { "cash": 40, "fear_mana": 10 },
    "gate": { "requires_tags": [], "requires_rooms": [] },
    "tags_added": ["hardened"]
  }
]
```

| Field | Type | Purpose |
|---|---|---|
| `id` / `display_name` / `description` | string | Same conventions as chamber upgrades. |
| `compatible_types` | string[] | Fixed to `["minion"]`; mirrors the field name so minion and chamber upgrades share one loader if merged later. |
| `cost` | map | Resources required at purchase (day phase, anytime). |
| `gate.requires_tags` | string[] (optional) | Minion must carry all listed tags for the upgrade to be selectable (e.g., a *broken* minion's obedience gear). |
| `gate.requires_rooms` | string[] (optional) | These chamber types must exist built (mirrors conversion template gating — e.g., lab-forged upgrades need the Basic Lab). |
| `tags_added` | string[] | Tags applied to the minion on purchase. The entire mechanical payload in v1. |

### Purchase Procedure

```
1. Validate: slot empty OR replacement policy decided (v1: one-time, no re-purchase of a
   different upgrade after one is installed — see Extensibility).
2. Validate gate against minion tags / built rooms; validate + pay cost.
3. Apply tags_added via minion_tag_add(); minion_refresh_appearance().
4. Append history line: { cycle, "They were reforged as <upgrade display name>." } (or authored text per upgrade — add optional `text` field to schema).
```

## Appearance

The sprite is **derived from the tag list**, not stored independently in data files: a lookup table maps (in priority order) matching tags → sprite. First match wins; default base minion sprite if nothing matches.

```json
// datafiles/minion_appearances.json
[
  { "matches": ["bionic_hand"],   "sprite": "spr_minion_bionic" },
  { "matches": ["scarred"],      "sprite": "spr_minion_scarred" },
  { "matches": ["broken"],       "sprite": "spr_minion_broken" },
  { "matches": ["devoted"],      "sprite": "spr_minion_devoted" }
]
```

Order in the file is priority order (topmost wins on multiple matches), so appearance tracks the most visually distinctive tag. Resolved at creation and after every `tags` mutation via `minion_refresh_appearance()`. This keeps appearance automatically correct as tags escalate (experimented → degraded → scarred) without any room code knowing about sprites.

## Backstory & History

- **Backstory**: authored pool in `backstories.json` — short paragraphs with no base mechanical effect ("the bishop who shouldn't be here", "the virgin"…). A random entry is assigned when each guest/client is created (see [`CLIENT_SYSTEM_SPEC.md`](CLIENT_SYSTEM_SPEC.md)) and copied verbatim to the minion at conversion. Spending Influence reveals a guest's background (GDD §7) — i.e., it's known data gated behind UI, not generated on reveal.
- **History**: `history[]` of `{ cycle: int, text: string }`, flavour only. Written by:
  | Source | Example |
  |---|---|
  | Conversion | Template's `text` — always line item #1. |
  | Terminal events | Cull/flee/restore outcomes (once the future status pipeline lands); also friend story terminals (Autumn capture, Winter sacrifice). |
  | Upgrades | Purchase event line. |
  | Story beats | Best-friend arc paragraphs, ally-gateway moments, authored narrative triggers. |
  | Random room-flavoured entries | Low-chance per-night flavour lines drawn from a pool keyed to the minion's current chamber (pure presentation; never mechanical). |

Because history is never read mechanically, writers can add entries freely without touching game logic — but any *meaningful* consequence must be expressed as a tag so effects stay on the single mechanical surface.

## Interaction with Other Systems

| System | Interface |
|---|---|
| Chamber production (step 3 night pipeline) | Reads minion presence + `minion_has_tag` conditions from chamber bonus rules; minions never write resources directly. Multi-occupancy: a room with N minions still evaluates its contribution once per night (occupancy affects staffing, not output — unless a future rule says otherwise). |
| Reclamation (`reclaim` blocks) | Assignment-only gate + `nights_to_clear`; obstacle replaced by buildable slot on completion. |
| Client system | Source of identity/tags/backstory; guest destroyed at conversion; fixed-pool income reduced permanently (GDD §7 trade-off). |
| Friends (GDD §5/§8) | `is_friend` minions with authored identities; best friend is the first converted minion via scripted event, not this pipeline's Hunt path. Nerd protection (halts tag accumulation for self + roommates) applies to whatever nightly tag system exists at implementation time — in v1 there are no nightly tags yet, so it's a no-op until the future pipeline lands. |

## Extensibility Notes

- **New template** → one JSON entry; UI list auto-populates.
- **New quirk** (beyond Devoted/Broken/Terrified) → new `quirk` string + its tags in `tags_added`; no code change unless it needs unique behaviour, in which case key off the tag.
- **Swap upgrades / re-roll slot** → add a `replace_cost` or allow multiple slots (`upgrade_id` → array). Schema already avoids hard-coding single-slot in data fields.
- **Numeric upgrade effects** → extend schema with an `effects` map mirroring chamber upgrades; read by whichever systems need it (production multipliers, reclamation duration reduction).
- **Per-night tag application & status pipeline** → see [FUTURE_FEATURES.md](FUTURE_FEATURES.md) — designed in full, deliberately deferred.
