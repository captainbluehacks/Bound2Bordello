# AGENTS.md — Bound to the Bordello

Operating guide for AI agents (and humans) working in this repo. Game context lives in [README.md](README.md) and [Game-Design-Document.md](Game-Design-Document.md); this file covers layout, conventions, gotchas, and CI/test contracts. Where a spec doc and this file disagree, the spec doc wins — update this file when reality changes.

## Project snapshot

Dark-comedy horror base-builder / management sim in **GameMaker Studio (LTS 2026)**, written in GML. The simulation is data-driven: room/minion/client definitions live as JSON in `datafiles/`, logic lives in named functions under `scripts/`. Chamber contribution engine and the day/night/reckoning cycle are implemented; minion and client systems are partially implemented (see spec status flags).

## Repo layout & where things live

```
Bound2Bordello/
├── Bound to the Bordello.yyp        # GameMaker project file
├── datafiles/                       # JSON game data — the source of truth for balance/content
│   ├── chamber_types/               #   per-ally room type definitions (succubus.json, …)
│   ├── upgrades/                    #   per-ally upgrade definitions
│   ├── backgrounds/                 #   client background pools
│   ├── attic|basement|first|ground.json  # per-floor layout & reclamation data
│   ├── client_pools.json            #   seasonal client pool definitions
│   └── names.json                   #   name pools
├── scripts/                         # Core logic — named functions, one folder per script
│   ├── scr_chamber_calc/            #   chamber contribution engine
│   ├── scr_mansion_grid|layout|constants/  # grid geometry, floors, constants
│   ├── scr_people_manager_helpers/  #   people (client/minion) helpers
│   ├── scr_ui_*                     #   UI system, panels, colours
│   ├── test_*/                      #   GMTL test suites + test_helpers (see Testing)
│   └── GMTL_*/                      #   vendored GameMaker Testing Library — DO NOT EDIT
├── objects/                         # obj_chamber, people system (obj_person/client/minion), managers, UI
├── rooms/                           # rm_test → rm_init → rm_start
├── sprites|sounds|fonts|options/    # assets & platform options
├── tools/run_tests.sh               # local CI: Igor build + GMTL run (see Testing)
├── .github/workflows/               # CI: GML Code Scanner, asset size/LFS guard
└── .lmstudio/mcp.json               # project-level GameMaker MCP server config
```

### Spec documents (repo root)

| Document | Covers |
|----------|--------|
| `Game-Design-Document.md` | High-level concept, core loop, economy, narrative arc |
| `CHAMBER_SYSTEM_SPEC.md` | Chamber contribution engine: JSON schemas, calculation pipeline, adjacency, floor mapping & reclamation |
| `CLIENT_SYSTEM_SPEC.md` | Guest/client system: fixed pool generation, seasonal growth, night funnel, conversion handoff |
| `MINION_SYSTEM_SPEC.md` | Minion identity & tags: conversion, assignment, reclamation gating, appearance. **Supersedes the old MINION_STATE_SPEC** — its nightly tag pipeline is now deferred in FUTURE_FEATURES |
| `FUTURE_FEATURES.md` | Designed-but-deferred mechanics (tag status pipeline, rest rooms, draft upgrades) |
| `TESTING_PLAN.md` | GMTL strategy, suite breakdown, test conventions (§3), local CI notes |

Specs flag unimplemented behaviour as **spec-only** — treat those sections as acceptance criteria, not descriptions of current code.

## GML conventions

- **Naming prefixes:** `scr_` scripts, `obj_` objects, `spr_` sprites, `rm_` rooms, `COL_` colour macros. Test suites live in `scripts/test_<system>/` folders; shared fixtures go in `test_helpers`.
- **Functions, not event blocks:** logic lives in named functions inside scripts (`function foo() { … }`). Keep object events thin — they call into scripts. Use `var` for locals; instance variables only for state that must persist or be read elsewhere.
- **JSDoc on every named function:** each `function` gets a `/// @description` block directly above it, with accurate `@param` and `@return` entries (omit `@return` when the function returns nothing). GameMaker's JSDoc syntax is strict: types go in `{braces}`, optional params are written `{type} [name] desc.` — brackets around the *name* only, never the type. Don't invent tags (`@param_pool`, etc.). Keep blocks in sync when a signature changes; vendored `GMTL_*` code is out of scope.
- **Colours:** always use the `COL_*` macros from [scripts/scr_ui_colours.gml](scripts/scr_ui_colours/scr_ui_colours.gml) (parchment theme). Colours are pure `0xRRGGBB` hex values; **alpha is separate** — pair with the matching `*_ALPHA` macro and `draw_set_alpha`. Never bake alpha into a colour value.
- **Data structures:** prefer native `struct {}` and array `[]` by default — both are garbage-collected automatically. Reach for `ds_*` only when you need a capability they lack:
  - `ds_grid` — 2D grids (e.g. `global.mansion_map`); no native equivalent
  - `ds_set` — O(1) unique membership; no native set type
  - `ds_queue` / `ds_stack` — O(1) head operations on large collections
  - `ds_map` — non-string keys (raw numbers / instance IDs without `string()` conversion)

  Any `ds_*` you create **must be explicitly destroyed** (`ds_*_destroy`) — pair creation with destruction and keep ownership obvious. Don't stash struct/array references in globals longer than needed; they live as long as the last reference does.
- **Null sentinel:** use `noone` for empty instance/DS references (see Gotchas). Guard possibly-stale instance refs with `instance_exists(id)` before dereferencing.
- **Event discipline:** initialize in Create, simulate in Step, render only in Draw (never mutate gameplay state there). Use enum + switch state machines instead of boolean flag tangles. Clean up anything you allocated when the owning object/room ends.

## Gotchas — current syntax vs training data

This project targets GameMaker **LTS 2026**. Model training data and older docs describe APIs that no longer exist or behave differently. **Verify any function against current GameMaker docs (the `Gamemaker Documentation` MCP server) before using it.** Known traps:

- **`noone`, not bare `no`.** In this GM build a bare `no` literal compiles as an unset variable read and throws at runtime. Use `noone` everywhere for null instance/DS references (see the note in [scripts/test_helpers/test_helpers.gml](scripts/test_helpers/test_helpers.gml)).
- **`make_colour_alpha()` does not exist** in current GML. For alpha, keep pure `0xRRGGBB` + `draw_set_alpha` (the project convention) or bit-shift: `(alpha << 24) | colour`. Closest real functions are `make_colour_rgb` / `make_colour_hsv`.
- **`map_exists()` no longer exists.** Use `struct_exists(s, "key")` for structs; `ds_map_exists(m, key)` only for actual ds_maps.
- Prefer current API patterns over legacy ones when both exist (e.g. `instance_create_layer` over `instance_create`).

## Testing

- **Framework:** GMTL v1.2, vendored under `scripts/GMTL_*`. Do not edit or remove those folders; configure via `GMTL_definitions.gml` (`gmtl_run_at_start`, `gmtl_show_coverage`).
- **Suites:** one suite per system in `scripts/test_*/` (currently `test_chamber_calc`, `test_mansion_grid`, `test_smoke`) with shared builders in `test_helpers`. Conventions: test behaviour not implementation, deterministic first, `each()` for table cases — full strategy in [TESTING_PLAN.md](TESTING_PLAN.md) §2–3.
- **Run locally:** `tools/run_tests.sh` from Git Bash (works from any directory). It compiles headlessly with Igor into `.ci/build/`, launches the build via `Runner.exe -game <file>.win` with `B2B_TEST_MODE=1`, and gates on exit code + the GMTL summary parsed from `test_output.log`.
  - Exit codes: **0** = all passed, **1** = tests failed / crash / hang (300 s timeout), **2** = build or environment problem.
  - Requires GameMaker LTS installed under `C:\ProgramData\GameMakerStudio2-LTS2026`.
  - In test mode, `obj_test_status` calls `game_end()` when GMTL finishes instead of entering gameplay (see [scripts/scr_test_harness](scripts/scr_test_harness/scr_test_harness.gml)).
- **Known CI gotchas** (from TESTING_PLAN.md §5): Igor needs backslash Windows paths; the `.win` output is an IFF archive launched via Runner, not executed directly; do **not** read `gmtl_coverage_*` counters after tests finish (hangs the VM); game file writes are sandboxed to `%LOCALAPPDATA%\Bound_to_the_Bordello`.

## CI expectations (GitHub Actions)

- **GML Code Scanner** (`.github/workflows/gml-code-scanner.yml`): runs `Mackery6969/GML-Code-Scanner@v2.1.0` on push to master and all PRs; results upload as **SARIF to the Security tab**. Keep new/changed GML scanner-clean. The action version is pinned deliberately (single-maintainer action) — bump it only intentionally.
- **Asset size / LFS guard** (`.github/workflows/check-file-size.yml`): changed `.png/.wav/.ogg/.mp3/.mks` files over **5 MB** must be tracked by Git LFS — add the type to `.gitattributes` before merging, or the PR fails.

## Git workflow

- The default branch is **`master`** and it is **protected**: every change requires a pull request with review before merge. Never push directly to `master`.
- **Do not rename `master` to `main`.** It's GameMaker IDE's git default, and the IDE's per-function green/red status indicators only work when the branch is named `master`. (The maintainer uses `main` convention elsewhere — if they say "main", they mean this branch.)
- Work on a feature branch, open the PR, and leave it for maintainer review — do not self-merge (no admin bypass of the review requirement).
- Branch naming: `<type>/<name>` (e.g. `feature/selection-panel`, `refactor/remove-sidebar`). Agent-created branches use the `bionic/` prefix (e.g. `bionic/ci/local-test-pipeline`).
- Remote: `https://github.com/captainbluehacks/Bound2Bordello.git`.

## Tooling notes

- **GameMaker MCP** (appears as *GameMaker Project Assistance* in Bionic's MCP list): configured per-project in [.lmstudio/mcp.json](.lmstudio/mcp.json) — stdio `gamemaker-mcp` server, pointed at this `.yyp`. Env vars: `GAMEMAKER_MCP_MODE` controls access mode, `GM_MCP_TOOL_MODE=full` exposes the complete toolset, `GAMEMAKER_MCP_ALLOW_BUILD=1` permits Igor builds via `gm_build`.
- **Builds:** Igor lives under `C:\ProgramData\GameMakerStudio2-LTS2026\Cache\runtimes\runtime-*` (latest wins); user/licence folder under `%APPDATA%\GameMakerStudio2-LTS2026`.
