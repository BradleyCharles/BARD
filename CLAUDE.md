# BARD — Claude Code Instructions

## Project Map

**Read [`docs/project_map.md`](docs/project_map.md) at the start of every new task.**

It contains:
- Full directory structure with file-level descriptions
- All key systems and their public APIs
- Bounty data flow diagram
- Data format schemas
- Technology stack and phase status
- Implementation notes for non-obvious design decisions

**Update `docs/project_map.md` whenever you:**
- Add, remove, or rename a script or scene
- Add a new feature or system
- Change a key API (signals, exported functions, data schema fields)
- Change the directory structure

Keep the map accurate — it is the primary orientation document for this codebase.

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

## Repo Layout (Short Form)

```
autoload/scene_manager.gd   ← global singleton
Player/player.gd            ← player movement, combat, health
npc/npc_base.gd             ← all NPCs share this base
world/field.gd              ← Ashfield (hunting zone)
world/town.gd               ← Thornwall (town scene)
ui/                         ← all HUD and overlay scripts
mob/slime1.gd               ← only active enemy type
pipeline/                   ← Python LLM pipeline
data/bounty_pool.json       ← static bounty definitions
dialogue/                   ← LLM-generated per-NPC per-day JSON
```
