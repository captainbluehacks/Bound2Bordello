# Client (Guest) System — Technical Specification

This spec defines **guests/clients**: the fixed pool of humans who visit the Bordello each night, generate income, and serve as the raw material for minion conversion. It is intentionally small — a guest's whole lifecycle is *spawn → visit → income or convert*.

Companion specs:
- [`MINION_SYSTEM_SPEC.md`](MINION_SYSTEM_SPEC.md) — what happens to a guest on conversion (identity/tags/backstory copy, template application).
- [`CHAMBER_SYSTEM_SPEC.md`](CHAMBER_SYSTEM_SPEC.md) — room-side `clients[]` array, `client_capacity`, `requires.client`, and the night funnel.
- [`Game-Design-Document.md`](Game-Design-Document.md) — design intent (§2 The Hunt, §7 Guest Pool / Preferences & Backgrounds / Conversion Cost).

## Overview

A guest is a named instance in `obj_client`. Guests:

- Belong to a **fixed pool** generated at the start of the playthrough (not regenerated per night), sized per season/town (GDD §7 — village starts ~6; town bias and seasonal pools are data-driven). New guests are added to the pool at the start of each subsequent season as new towns' visitors arrive.
- Carry a **name**, a flat **tag array** (preferences/identity), and one **backstory**. All three come from JSON pools at creation.
- Visit on a rolled **visit frequency**; present guests are funneled into rooms each night and generate Secondary resources when their preferences match the room.
- Can be **converted** during The Hunt: escorting them into a `private`-tagged chamber creates a minion (new object) and **destroys the guest permanently**, shrinking the income pool for the rest of the run.

Design invariant (same as minions): **tags are the only mechanical surface.** A guest's tags drive preference matching, conversion discounts, and — after conversion — carry over verbatim into the minion. Name and backstory are flavour-only.

## File Layout

```
datafiles/
    client_names.json     ← guest name pool (random pick at creation)
    guest_pools.json      ← seasonal/town pool definitions (size, tag distributions, visit frequencies, background file)

datafiles/backgrounds/
    village.json      		← background paragraph pool (shared with minions on copy)
	industrial-town.json    ← background paragraph pool (shared with minions on copy)
	wealthy-suburbs.json    ← background paragraph pool (shared with minions on copy)
	city.json      			← background paragraph pool (shared with minions on copy)

objects/
    obj_client/           ← guest instance: identity + per-night state vars (below)
```

## Guest Instance Variables (`obj_client`)

| Variable | Type | Purpose |
|---|---|---|
| `client_id` | int/string | Unique ID (save-system-ready). |
| `name` | string | Display name; random pick from `client_names.json`, no duplicates within the active pool. |
| `tags` | string[] | Flat tag list — preferences/identity (`dominant`, `submissive`, `violent`, …) drawn from the season/town's distribution. Drives preference matching and conversion discounts; copied verbatim to a minion on conversion. |
| `backstory` | string | Random pick from `backstories.json`. Flavour only — but *revealing* it (spending Influence, GDD §7) applies that client's personal conversion-cost discount. Known-vs-unknown is UI state, not generated data: the backstory always exists; spending Influence just unlocks viewing it and the discount. |
| `visit_frequency` | float (0–1) | Chance to visit on any given night; rolled at pool generation per the town/season profile. |
| `converted` | bool | `true` once converted — excluded from future visitor rolls permanently. (Instance is destroyed, but this field documents intent for save reconstruction.) |
| `target_room` | instance or `no` | Current funnel target for the night (set by the search state). Transient; reset each cycle. |
| `state` | string (`"searching"` / `"moving"` / `"paying"`) | Per-night behaviour machine (below). Existing prototype implements exactly these three states. |

## Pool Generation & Visit Frequency

- **Generation**: at playthrough start, build the initial guest pool from `guest_pools.json`: pick N guests for the village, roll name/tags/backstory/visit_frequency from the town's distributions. Town tag bias is just a weighted tag distribution in data — no special code.
- **Seasonal pool growth**: at the start of each new season, generate and add that season's new-town guests to the existing pool (GDD §7). Existing guests remain; converted guests stay removed. The pool only grows (by season) or shrinks (by conversion).
- **Nightly visitor list** (GDD §2 End of Cycle): for each non-converted guest, roll `random() < visit_frequency` to build tomorrow's visitors. Converted guests never roll again.
- **Night funnel**: present guests spawn at the door and enter rooms per their existing state machine (`searching → moving → paying`, prototype in `obj_client/Step_0.gml`). Room-side: a chamber holds up to `client_capacity` guests in its `clients[]` array (see [`CHAMBER_SYSTEM_SPEC.md`](CHAMBER_SYSTEM_SPEC.md)); most rooms have capacity 1, multi-client rooms (e.g., The Bar) have higher capacity. A room only produces for its guests if `requires.client` is satisfied **and** preference conditions are met.
- **Income**: satisfied guests pay on arrival (`paying` state → alarm). This is the flat per-night income that conversion permanently removes from future cycles — no other mechanical role.

## Conversion Handoff (Interface to Minion Spec)

The full conversion procedure lives in [`MINION_SYSTEM_SPEC.md`](MINION_SYSTEM_SPEC.md#conversion); this spec only defines what a guest *supplies* and what happens to it:

| Guest data | Fate at conversion |
|---|---|
| `name` | Stored as `guest_name` on the new minion (reference/flavour). Also used as default minion name if the player skips the 3-pick. |
| `tags` | Copied verbatim into the new minion's tag array (then template add/remove applied). |
| `backstory` | Copied verbatim; becomes the minion's backstory. |
| `visit_frequency`, `state`, funnel vars | Discarded — meaningless on a minion. |
| The instance itself | **Destroyed**; guest removed from the fixed pool permanently ("every minion gained is income you will never earn again", GDD §7). The guest has already produced their income for the current night (The Hunt occurs after Production); conversion forfeits all *future* nights of that client's potential earnings. |

Cost/discount model (GDD §7 Conversion Cost) applies here at the UI/prompt boundary: template base cost − up to 2 preference-tag matches between the target `private` room (+ upgrades) and the guest's tags − background-knowledge discount if Influence was spent on this client. The minion spec handles paying; **this** spec owns computing the match/discount inputs from the guest's tag list.

## Extensibility Notes

- **New town/season pool** → one JSON entry in `guest_pools.json` (size, weighted tags, frequency range). A json file containing the backgrounds for that town. No code change.
- **Named/villain guests with authored identity** (e.g., a recurring story client) → an optional `authored: true` flag on a pool entry that supplies fixed name/backstory/tags instead of rolls; the rest of the pipeline is unchanged.
- **Guests returning after conversion** (a converted minion's "life before" reappearing, or a redeemed guest) → out of scope; would need a `returning_guest` mechanic and its own section in [`FUTURE_FEATURES.md`](FUTURE_FEATURES.md).
