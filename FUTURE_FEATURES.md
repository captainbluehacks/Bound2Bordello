# Future Features — Designed but Deferred

These mechanics are fully designed now so the schema and code boundaries can accommodate them from day one, but **no v1 code implements them**. Each section notes exactly what must change (or need not) when it ships.

---

## 1. Minion Tag Status Pipeline (Nightly Tags, Progression & Outcomes)

*Supersedes the nightly pipeline in the retired `MINION_STATE_SPEC.md`, restructured for a single flat tag array.*

### Design intent

A minion assigned to a chamber can accumulate **tags** from it overnight — e.g., `experimented` → `degraded` → `scarred` (progression) in the Mad Scientist Lab, or recovery tags from rest rooms. A minion with too many negative-context tags either dies (`cull`) or flees; players who value them can pay to keep them. This is what gives chambers *consequences*: the Mad Scientist Lab's experiments only ever produce anything because a minion accumulates a `bionic_hand` (or similar) tag — but pushing too far risks losing the minion entirely, so the player must rotate staff in and out of rooms.

Tags are **contextual, not polar**: a tag is never inherently good or bad. The same tag can be valuable to one client, useful for reclamation, or fatal-in-a-room depending on where it appears. Effects trigger purely by presence via room rules (`minion_has_tag`), upgrades, and reclamation gates — so no code distinguishes "good" from "bad." What *is* tracked per tag is **status behaviour** (see Status Behaviours).

### Data schema: `datafiles/minion_tags.json`

```json
{
  "tags": [
    { "id": "experimented",      "behaviour": "progression", "track": ["degraded"] },
    { "id": "degraded",          "behaviour": "progression", "track": ["scarred"] },
    { "id": "scarred",           "behaviour": "terminal",    "outcomes": [0.7, 0.3] },
    { "id": "bionic_hand",       "behaviour": "static" },
    { "id": "rested",            "behaviour": "decay" }
  ],

  "outcome_weights": {
    "default": [1.0, 0.0],
    "devoted":   [0.2, 0.8],
    "broken":    [1.0, 0.0]
  },

  "outcome_definitions": [
    { "index": 0, "name": "cull",    "description": "The house discards them." },
    { "index": 1, "name": "flee",    "description": "They slip out into the night and never return." }
  ]
}
```

| Field | Purpose |
|---|---|
| `tags[].id` | Tag identifier (same string used in room effects, upgrades, reclamation gates). |
| `tags[].behaviour` | One of: `progression`, `terminal`, `decay`, `static`. Drives status handling only — *not* good/bad classification. |
| `tags[].track` | Next tag(s) this one promotes into (see below). Terminal/decay/static tags omit it or leave it empty. |
| `tags[].outcomes` | For terminal tags: weight vector over `outcome_definitions`. **The player's choice is a weight modifier on this table**, not a separate mechanic. |
| `outcome_weights[quirk]` (or `[tag]`) | Overrides the default outcome weights when the minion carries that quirk/tag. This is where "a *devoted* minion is much less likely to flee and more likely to be culled" lives — the same data pattern covers any future tag-driven modifier. |
| `outcome_definitions` | Named, ordered outcomes: index 0 = cull (destroyed), index 1 = flee (removed from the house; possible return via a future "returning minion" feature). Add more indices later without breaking anything — only weights change shape. |

### Status behaviours

| Behaviour | Nightly handling |
|---|---|
| `progression` | While held, promotes along `track` to the next tag at night resolution (with a chance per room rule, or 100% as configured). A minion can hold only one tag per progression chain — promotion replaces the current link. |
| `terminal` | Triggers an outcome roll on arrival: weights from `outcome_weights`, starting from the tag's own `outcomes` vector if present. Resolution order below. |
| `decay` | Countdown tag (e.g., `rested`): each night without re-application loses one charge; auto-removes at zero. Add optional `charges` field to schema when needed — v1 of this feature can use fixed counts per room rule instead. |
| `static` | No automatic behaviour; purely meaningful through room rules/upgrades/gates (`bionic_hand`). Most tags are this. |

### Room-side effects (chamber types)

The chamber spec already reserves `minion_effects` on each chamber type — this feature activates it:

```json
"minion_effects": {
  "apply_chance": 0.5,
  "actions": [
    { "type": "add_tag",       "tag": "experimented" },
    { "type": "progress_tag",  "from": "experimented", "to": "degraded" },
    { "type": "remove_tag",    "tag": "rested" }
  ]
}
```

Each assigned minion rolls `apply_chance` once per night, then the actions apply (in order). Action types compose: a room can both add and progress. A minion assigned to an obstacle or unassigned gets no effects (obstacles produce nothing anyway — see reclamation gating in [`MINION_SYSTEM_SPEC.md`](MINION_SYSTEM_SPEC.md)).

**Nerd protection carve-out** (GDD §5): if the best friend is *nerd* (no tags), they and every minion in their assigned room are exempt from `minion_effects` application that night. Implementation: one boolean check per chamber before its effect roll; no other system needs to know.

### Night resolution order (extended pipeline)

Inserted after step 3 (Production & Contribution) of the [`CHAMBER_SYSTEM_SPEC.md`](CHAMBER_SYSTEM_SPEC.md) pipeline:

```
4. Minion Status Resolution   ← this feature
   For each minion, per their current chamber:
     a. Apply minion_effects (chance roll → actions).
     b. Process progression chains to completion (A→B→C in one night if the room grants multiple steps).
     c. If a terminal tag was reached: resolve outcome —
        1. Weighted pick by quirk/tag-modified table.
        2. On "flee" (index 1): if the player chooses to pay the Keep cost
           (derived from the minion's current value/tags; default = flat cash cost, tunable per quirk),
           the flee is prevented and the terminal tag is replaced by a recovery state
           (e.g., removed or set back one chain step).
        3. On "cull" (index 0): destroy the minion instance, clear from chamber.minions[],
           append final history line.
   d. Random room-flavoured history entries roll here too (chance per chamber type, pool keyed by chamber — see MINION_SYSTEM_SPEC.md §History).
5. Story beats / narrative triggers.
6. Cycle rollover: cycle += 1; refill guest pool to fixed size.
```

### What changes when this ships

| Area | Change |
|---|---|
| `obj_minion` | Nothing — `tags[]`, `history[]`, and quirk already exist for other reasons. Only the night pipeline writes them more aggressively. |
| Chamber types | Fill in `minion_effects` on experimental/rest rooms; no schema change (field is reserved now). |
| Conversion templates / upgrades / reclamation gates | No changes — they already read/write plain tags, which is all this feature produces/consumes. |
| UI | New "status" column on the minion panel showing active progression chain + terminal risk highlight (e.g., *scarred* blinks). Keep-cost button appears when a flee roll succeeds against the player's choice point. |

**Out of scope even here:** tag-based production multipliers on the minion side, seasonal/tag-driven room ambience shifts, returning-fled-minions feature — each gets its own section if/when designed.

---

## 2. Draft-Style Minion Upgrade Selection

### Design intent

Instead of a plain list, minion upgrades present as **three random choices per day phase** (draft model): pick at most one card, or skip the draft to keep all three for tomorrow. Cards are drawn from `datafiles/minion_upgrades.json` (same data file — this feature only changes presentation + draw rules), weighted toward what's currently relevant (see below).

This creates daily decision texture: "I want Hardened Hide but it hasn't come up yet" vs "take the cheap tag I can use today." It mirrors draft/pick mechanics players recognise from roguelikes without adding a new card system — chambers keep their plain list (their choices are permanent builds, not per-day drafts).

### Data: no new fields required in v1 of this feature

The existing minion upgrade schema (`id`, `display_name`, `description`, `compatible_types`, `cost`, `gate`, `tags_added`) is sufficient. Optional additions for tuning the draft pool (add when needed):

| Field | Purpose |
|---|---|
| `weight` (int, default 1) | Relative draw frequency in the daily pool. |
| `exclusive_with` (string[]) | Never appears on the same board as another listed upgrade ID. |
| `once_per_run` (bool, optional) | Removes itself from the pool after being purchased once anywhere (for one-shot story upgrades). |

### Draft rules

```
At start of each day phase:
1. Build eligible pool:
   - All minion upgrades whose gate passes for at least one existing minion
     (i.e., requires_tags matches some minion's tags, and requires_rooms are built).
   - Upgrades already installed on any minion are excluded from the pool
     (one slot per minion; no re-drawing an owned card in v1 — `once_per_run` extends this to global exclusion if needed).
2. Draw 3 distinct cards from the eligible pool using weight-based sampling.
3. Player may install at most ONE card during this day phase, on ANY minion whose
   own gate passes and which has an empty upgrade slot; or SKIP (board carries over unchanged —
   it does NOT re-roll).
4. On cycle rollover: board resets to a fresh 3-card draw regardless of whether the player acted.
```

### Edge cases

| Situation | Handling |
|---|---|
| No minions exist yet | Board is hidden entirely (nothing eligible); no day phase is "lost" — it simply isn't offered until the first conversion. |
| Fewer than 3 eligible cards | Fill with generic/low-cost baseline upgrades (reserve a small always-eligible base set in the data file, e.g., cheap tag grants with empty gates). |
| Player converts a new minion mid-day after seeing the board | Board is unchanged; the new minion can use whatever's on offer if its gate passes. |
| Player buys card for minion A, then assigns that minion to an obstacle (which removes them from production but not identity) | Upgrade stays installed — upgrades are permanent identity, not room-bound. Only death/flee removes a minion and their upgrade with them. |

### What changes when this ships

| Area | Change |
|---|---|
| UI | New draft board panel in day phase; card hover shows full description + compatible-minion list. "Skip" is the default (no confirmation needed). |
| `scr_minions.gml` / upgrade purchase path | Add a per-cycle draft-state object: `{ drawn_cards[3], one_picked_this_cycle: bool }`. Purchase handler checks it before allowing install; resets on cycle rollover. |
| Data file | Same JSON; just author 6–10 upgrades minimum so the pool isn't thin for early game. |

---

## 3. Rest Rooms & Minion Recovery

### Design intent

Rest rooms (the Dormitory's spiritual family) let worn-down minions recover: clear negative-context tags, prevent progression chains from advancing while the minion is resting, and/or restore decayed charge tags. This gives the player a **rotation strategy** — push a minion through a Mad Scientist Lab chain until they're useful, then park them in rest to stabilize before their terminal tag rolls.

Rest rooms are ordinary chambers: they have `occupancy` (default 1), can hold one or more minions via normal assignment, and produce nothing by themselves unless given an explicit contribution rule (rest is the "product" — its value shows up as *avoided losses*, not direct resources). No new room type machinery needed.

### Data: chamber types use existing `minion_effects` + reserved recovery fields

```json
{
  "id": "dormitory",
  "display_name": "Dormitory",
  "tags": ["rest"],
  "occupancy": 3,
  "cost": { "cash": 60 },
  "contribution_rule": null,
  "minion_effects": {
    "apply_chance": 1.0,
    "actions": [
      { "type": "remove_tag",  "tag": "degraded" },
      { "type": "hold_progression" }
    ],
    "recovery_actions": [
      { "type": "restore_terminal_from", "tag": "scarred", "to": "degraded", "chance": 0.5 }
    ]
  }
}
```

| Field | Purpose |
|---|---|
| `occupancy` (≥1) | How many minions can rest simultaneously; Dormitory example uses 3 so multiple staff rotate through one room. Single-occupancy "Quiet Corner" variant = same schema, occupancy 1, cheaper. |
| `minion_effects.actions[]` | Standard actions from the tag pipeline: `remove_tag` on specific chain links (reverses progression by one step per night at apply_chance), or `hold_progression` (suppresses this room's own *and* any carried-over advancement this night — effectively "freezes" the minion). |
| `minion_effects.recovery_actions[]` *(reserved, new field)* | Specialised recovery entries for rest rooms: e.g., chance to pull a terminal tag back one step before its outcome rolls. Add this key only when implementing; until then rest = remove_tag + hold_progression, which covers most of the design space without it. |
| `contribution_rule` | Typically null (rest produces nothing). A future "Comfort" chamber could grant a small cash bonus for each fully-rested minion (no degraded/experimented tags present) — same existing schema, no new machinery. |

### Interaction with the tag pipeline

- Rest rooms participate in step 4 of the night resolution order exactly like any other chamber: their `minion_effects` apply to whoever is assigned, using the same chance/sequence logic.
- A minion can be in at most one room per night (assignment exclusivity), so rest and experimental rooms are naturally mutually exclusive — no conflict-resolution code needed.
- **Recovery vs outcome timing:** if a minion enters their terminal tag *and* is resting in the same night, recovery_actions resolve first (rest "catches" them); only an uncaptured terminal triggers the cull/flee roll. This makes rest rooms a genuine hedge rather than cosmetics.

### What changes when this ships

| Area | Change |
|---|---|
| Chamber types JSON | Author 1–3 rest room variants (Quiet Corner / Dormitory / Grand Rest Hall scaling occupancy and cost). No schema change needed if only using remove_tag + hold_progression. |
| `minion_effects` action set | Add `hold_progression` as a no-arg action type (suppress advancement for that minion/night). Optional: add `recovery_actions` key to the chamber schema (see above) for terminal-reversal chances. |
| UI | Minion panel shows current chain state + "resting" badge when assigned to an occupancy>1 rest room, so the player can see rotation at a glance. No new screens — just assignment (which already exists). |

---

## Cross-Cutting Notes

- **None of these three features change existing data-file schemas** except for clearly-marked optional additions (`recovery_actions`, draft-pool tuning fields) that are additive and backward-compatible.
- **The single flat tag array is the contract.** All three features read/write `tags[]` via the same helpers from [`MINION_SYSTEM_SPEC.md`](MINION_SYSTEM_SPEC.md); nothing introduces a second classification surface (no hidden status enum, no good/bad flag). If any of them feels like it *needs* one, that's the signal to stop and extend this document first.
- **Shipment order suggestion:** Tag Status Pipeline → Rest Rooms → Draft Selection. The pipeline is prerequisite for rest rooms to matter; draft selection is independent UI work that can slip without blocking either.
