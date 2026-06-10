# BARD — Claude Code Instructions

## Documentation Rules (mandatory)

These rules are not optional. Failing to follow them wastes debugging time.

### Read before you act

| Working on... | Read first |
|---|---|
| Any new task | `docs/project_map.md` |
| Combat, collision, AI, physics | `docs/game_mechanics.md` |
| Bounty, dialogue, scene transitions, save/load, end-of-day, LLM pipeline, world gen, weapon shop, NPC behaviour, mob spawning, boss triggers, HUD/overlays | `docs/game_systems.md` |
| Player stats, tuning constants, exports | `docs/project_map.md` § PlayerStats table |

If a doc could answer the question or reveal the root cause, read it first — before grepping, before guessing.

### Task list discipline

For any task that reads a doc and uses that information, create a task list before starting work. The last item on the list must always be **Update docs**. This ensures the docs folder stays a live information center and doc updates are never skipped.

Example task list shape:
1. Read relevant doc(s)
2. [implementation steps]
3. Update docs

### Update after you act

Update the relevant doc **as the final step of the task**, matching what was actually changed — not later, not as a follow-up.

**Update `docs/project_map.md` when you:**
- Add, remove, or rename a script or scene
- Add, remove, or change any constant/export in a `*_stats.gd` or `*_data.gd` file
- Add a new feature or system
- Change a key API (signals, exported functions, data schema fields)
- Change the directory structure

**Update `docs/game_mechanics.md` when you:**
- Add or change collision layer/mask assignments on any entity
- Add or modify a damage pathway (HurtArea, SwordHitbox, or new attack types)
- Add, remove, or change mob AI behaviour (chase, flee, contact stop, knockback)
- Add a new enemy or NPC type
- Fix a combat or physics bug — document what was wrong and why

---

## Game Systems Reference

**Read [`docs/game_systems.md`](docs/game_systems.md) before working on any of these areas:**
bounty system, dialogue, scene transitions, save/load, end-of-day, LLM pipeline, world generation, weapon shop/upgrades, NPC behaviour, mob spawning, boss triggers, or the progress bar/loading overlay.

It contains:
- End-to-end flow for every major game system with sequence steps
- Data formats and file ownership (what writes what, what reads what)
- Edge cases, guards, and rules that are not obvious from the code
- How systems interconnect (e.g. dialogue actions → SceneManager → pipeline)

**Update `docs/game_systems.md` whenever you:**
- Add, remove, or significantly change any feature listed in its Table of Contents
- Change a data file format (bounty_pool, game_state, dialogue JSON, save files)
- Add a new pipeline mode, LLM prompt, or flag file
- Add a new UI overlay, HUD, or scene-level system
- Fix a bug caused by a misunderstanding of how a system works — document the corrected understanding

Keep it current — it is the single reference for how the game's features connect and behave.

---

## Project Overview

Godot 4.6 RPG demo with a local LLM (Ollama/Gemma 4 E4B) pipeline that regenerates NPC dialogue each in-game night based on game state. Academic project.

**Engine:** Godot 4.6 · GDScript
**Pipeline:** Python 3 scripts in `pipeline/`
**Key singleton:** `SceneManager` (`autoload/scene_manager.gd`) — owns all game state

## Code Conventions

- GDScript: use `@onready`, typed variables (`var x: int`), signal-driven UI updates.
- No comments unless the WHY is non-obvious.
- UI components are built entirely in code (no `.tscn` layout nodes for UI logic).
- All scene transitions go through `SceneManager.go_to_field()` / `go_to_town()`.
- UI reacts to signals (`bounties_updated`, `scripts_updated`, `player_health_changed`) — never poll state directly.
- Menus, overlays, and loading screens must be centered on screen. Use `PRESET_FULL_RECT` + `ALIGNMENT_CENTER` on VBoxContainers, or `PRESET_CENTER` + `grow_horizontal/vertical = GROW_DIRECTION_BOTH` on fixed-size panels. Never use bare `PRESET_CENTER` on a zero-size container — it anchors the top-left corner at screen center and pushes content into the bottom-right quadrant.

## GDScript Type Safety (required)

All GDScript variables must have explicit types. Never rely on `:=` inference when the right-hand side returns a `Variant` — the engine treats this as a warning-as-error. Affected patterns:

| Pattern | Problem | Fix |
|---------|---------|-----|
| `var x := dict.get(key, default)` | `.get()` returns `Variant` | `var x: Type = dict.get(key, default)` |
| `var x := array.get(key, default)` | same | explicit type |
| `var x := a in b` | `in` on Array/Dictionary returns `Variant` | `var x: bool = a in b` |
| `var x := node as SomeClass` | cast can return null (Variant) | `var x: SomeClass = node as SomeClass` |
| Signal parameters with no type hint | emitted value is untyped | annotate all signal params |

**Rule:** if `:=` would infer `Variant`, write the type explicitly instead.

## Component Separation

Features with distinct data or configuration concerns get their own script. Follow the existing patterns in `Player/`:

- **Stats / tuning data** (damage, speed, health, timers): live in a `*_stats.gd` or `*_data.gd` file with `class_name`, using `const` for primitive types and `static var` for Vector/object types. Never hardcode balance numbers inside logic scripts.
- **Per-weapon data**: add `Player/weapons/<weapon>_data.gd` using `sword_data.gd` or `axe_data.gd` as a template. Register the new weapon in `player.gd:_ready()` by adding an entry to `_weapon_stats`.
- **Input actions**: all input action name strings live in `Player/player_input.gd` (`class_name PlayerInput`). Use `PlayerInput.ATTACK` etc. throughout the project — never a bare `"attack"` string.
- **Distinct system behaviors**: if a node script grows to handle two unrelated responsibilities, split them into a host node + a child component node.

**Do not split when:**
- Logic is tightly coupled to the node's lifecycle (`_process`, `_ready`, signals wired to that node).
- The extracted file has no standalone meaning or re-use outside its host.
- It is under ~40 lines and a new file would only add navigation overhead.

---

## Repo Layout (Short Form)

```
autoload/scene_manager.gd          ← global singleton
Player/player.gd                   ← player movement, combat, health
Player/player_stats.gd             ← tuning constants (health, speed, dodge)
Player/player_input.gd             ← input action name constants (PlayerInput)
Player/weapons/sword_data.gd       ← sword stats (use as template for new weapons)
Player/weapons/axe_data.gd         ← axe stats
npc/npc_base.gd                    ← all NPCs share this base
world/field.gd                     ← Ashfield (hunting zone)
world/town.gd                      ← Thornwall (town scene)
ui/                                ← all HUD and overlay scripts
mob/slime1.gd                      ← only active enemy type
pipeline/                          ← Python LLM pipeline
data/bounty_pool.json              ← static bounty definitions
dialogue/                          ← LLM-generated per-NPC per-day JSON
```
