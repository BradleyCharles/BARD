# BARD — Project Map

**Game Name:** Erimentha  
**Engine:** Godot 4.6 (GDScript)  
**LLM Backend:** Ollama (Gemma 4 E4B, local inference)  
**Pipeline Language:** Python 3  
**Purpose:** Academic RPG demo — LLM-driven dynamic NPC dialogue

---

## Overview

BARD integrates a local LLM with a Godot 4 game. The player hunts slimes in a field, sleeps at an inn to end the day, and a Python pipeline generates new NPC dialogue based on game state before the next day begins. The dialogue system is the academic focus; the gameplay loop exists to feed it meaningful context.

```
Day N: hunt slimes → inn (end day) → end_of_day.py runs → Day N+1 dialogue written → repeat
```

---

## Directory Structure

```
BARD/
├── addons/                      # Godot plugins (currently empty)
├── archetypes/                  # NPC role templates for LLM pipeline
│   ├── blacksmith.json
│   ├── guild_commander.json
│   ├── innkeeper.json
│   ├── npc_generation_rules.json
│   ├── name_usage.json
│   └── generated/               # LLM-created NPC variants (by world_gen.py)
│       ├── blacksmith_A.json
│       ├── guild_commander_A.json
│       └── innkeeper_A.json
├── assets/                      # Sprite sheets
│   ├── Swordsman_lvl1/Without_shadow/   # Player: idle, walk, attack, hurt, death
│   ├── Slime1/Without_shadow/           # Enemy 1 (in use)
│   ├── Slime2/                          # Enemy 2 (not yet integrated)
│   └── Slime3/                          # Enemy 3 (not yet integrated)
├── autoload/
│   └── scene_manager.gd         # Global singleton: game state, pipeline orchestration
├── dialogue/                    # Generated day-specific NPC dialogue JSON
│   └── {npc_id}_day{N}.json
├── docs/                        # Documentation (this file)
├── fonts/
│   ├── almendra.regular.ttf     # Dialogue text
│   ├── almendra.bold.ttf
│   └── Xolonium-Regular.ttf    # UI labels
├── hud/                         # Legacy HUD (score/UI from earlier version)
│   ├── hud.gd
│   └── hud.tscn
├── main/                        # Legacy main scene
│   ├── main.gd
│   └── main.tscn
├── mob/                         # Enemy definitions
│   ├── slime1.gd
│   ├── slime1.tscn
│   └── mob.tscn
├── npc/                         # NPC system
│   ├── npc_base.gd              # Proximity detection, dialogue loading/merging
│   └── npc.tscn
├── pipeline/                    # Python LLM pipeline
│   ├── config.py                # Central config: paths, Ollama URL, model, world defs
│   ├── ollama_client.py         # Ollama HTTP wrapper with retry logic
│   ├── nl_descriptors.py        # Game state → natural language context builders
│   ├── end_of_day.py            # Main daily pipeline (called every night)
│   ├── chronicle.py             # Weekly summary generator (Ctrl+R)
│   ├── world_gen.py             # One-time setup: player name, lore, NPC variants
│   ├── fallbacks/               # Pre-generated fallback dialogue if LLM fails
│   │   ├── innkeeper_A.json
│   │   ├── blacksmith_A.json
│   │   ├── guild_commander_A.json
│   │   └── world_lore.json
│   └── lore/
│       └── thornwall.txt        # Hardcoded setting description used in prompts
├── Player/
│   ├── player.gd                # Movement, attack, animation, collision
│   └── player.tscn
├── ui/
│   ├── dialog_box.gd            # Typewriter effect, branching responses, actions
│   ├── dialog_box.tscn
│   ├── loading_screen.gd        # Overlay shown while pipeline runs
│   └── loading_screen.tscn
├── world/
│   ├── field.gd                 # Ashfield: mob spawning, respawn, day counter
│   ├── field.tscn
│   ├── town.gd                  # Thornwall: NPC setup from registry, dialogue reload
│   └── town.tscn
├── game_state.json              # Live game state: day, kills, bounties, flags, npc_facts
├── world_registry.json          # NPC-to-town assignments and variant IDs
├── world_lore.json              # Generated world lore used in LLM prompts
├── project.godot                # Godot engine config
├── pipeline_failed.flag         # Error sentinel (created if pipeline fails)
└── README.md
```

---

## Key Systems

### 1. SceneManager — `autoload/scene_manager.gd`

Global singleton (autoloaded). Owns all persistent game state.

| Method | Purpose |
|--------|---------|
| `end_day()` | Increment day, expire bounties, write game_state.json, launch pipeline |
| `go_to_field()` / `go_to_town()` | Scene transitions with loading overlay |
| `trigger_chronicle()` | Launch chronicle.py (Ctrl+R in town) |
| `_write_game_state()` | Serialize state to game_state.json |
| `_start_pipeline(mode)` | Launch Python script via `OS.create_process()` |

**State fields:** `day`, `monsters_killed_today` (dict), `active_bounties` (array), `flags` (dict), `player_name`

**Pipeline handshake:** Polls every 3 s for `pipeline_ready.flag`, `pipeline_failed.flag`, or `pipeline_crashed.flag`.

---

### 2. Player — `Player/player.gd`

8-directional movement (WASD/arrows), directional animations (idle/walk/attack/hurt/death), sword hitbox active on frames 2–6 of attack animation.

---

### 3. NPC Base — `npc/npc_base.gd`

Loads `dialogue/{npc_id}_day{N}.json` at scene start, merges LLM-generated "greeting" node with hard-coded role menus (inn sleep, bounty board, shop browse). Reloads on day change via `reload_dialogue()`.

**Collision layers:** Layer 1 = mobs, Layer 2 = player, Layer 3 = NPC detection radius.

---

### 4. Dialogue Box — `ui/dialog_box.gd`

Typewriter effect (0.028 s/char), branching response buttons (keyboard + mouse), dialogue actions: `end_day` (sleep at inn), scene transitions.

---

### 5. Field Scene — `world/field.gd`

3840×2160 px playable area, max 14 slimes, respawn delay 5–14 s after kill. South edge triggers `go_to_town()`. Records kills in `monsters_killed_today`.

---

### 6. Town Scene — `world/town.gd`

Applies NPC names/IDs from world_registry.json. Calls `reload_all_dialogue()` on scene load. Ctrl+R triggers chronicle pipeline.

---

### 7. Slime1 — `mob/slime1.gd`

Random direction every 2.5–6 s, 30% idle chance, speed 60–120 px/s. Death signal → field records kill → respawn timer starts.

---

## Python Pipeline

### world_gen.py — Run Once (Initial Setup)

Prompts for player name, generates world lore via LLM, creates NPC variants, writes `world_lore.json`, `world_registry.json`, `archetypes/generated/`, and `game_state.json`. Then calls `end_of_day.py` to generate Day 1 dialogue.

### end_of_day.py — Runs Every Night

For each named NPC:
1. Build natural language context (`nl_descriptors.py`)
2. Load NPC archetype variant
3. Construct LLM prompt (system prompt + game state + world lore + prior recollections)
4. Call Ollama `/api/generate`, parse JSON dialogue tree
5. Validate; repair if malformed; fall back to previous day's file if all else fails
6. Write `dialogue/{npc_id}_day{N}.json`
7. Extract recollection fact → append to `game_state.json npc_facts`

Outputs `pipeline_ready.flag` on success, `pipeline_failed.flag` on error.

### chronicle.py — Optional, Ctrl+R

Generates a multi-page chronicle/rumor sheet. No day advance.

### nl_descriptors.py — Context Builders

Converts game state fields to English prose for LLM prompts (kill summaries, bounty status, flags, historical trends).

### ollama_client.py — LLM HTTP Wrapper

POST to `http://localhost:11434/api/generate`, max 3 retries, 2 s delay, streaming response parsing.

### config.py — Central Config

Paths, Ollama URL/model, town/role definitions, retry settings. Model overridable via env var.

---

## Data Formats

### game_state.json

```json
{
  "meta": {"schema_version": "1.0", "day": 1},
  "player_name": "Hunter",
  "world_state": {
    "monsters_killed_today": {"slime1": 5},
    "monsters_killed_history": [{"slime1": 3}, {"slime1": 7}]
  },
  "active_bounties": [
    {"id": "bounty_001", "bounty_type": "slay", "target": "slime1",
     "target_count": 10, "completed_count": 0, "day_expires": 5}
  ],
  "flags": {"met_mira": true, "first_bounty_accepted": true},
  "npc_facts": {
    "yara_varen": {
      "facts": [{"text": "...", "added_day": 1, "weight": "recent", "source": "llm"}]
    }
  }
}
```

### world_registry.json

```json
{
  "towns": {
    "thornwall": {
      "display_name": "Thornwall",
      "npcs": {
        "innkeeper": {
          "archetype": "innkeeper", "variant_id": "innkeeper_A",
          "npc_id": "yara_varen", "display_name": "Yara Varen"
        }
      }
    }
  }
}
```

### dialogue/{npc_id}_day{N}.json

```json
{
  "npc_id": "yara_varen",
  "npc_name": "Yara Varen",
  "day": 1,
  "nodes": {
    "greeting": {
      "text": "...",
      "responses": [{"text": "...", "next": "node_id", "key": 1}]
    }
  }
}
```

---

## Technology Stack

| Component | Technology |
|-----------|-----------|
| Game engine | Godot 4.6, GDScript |
| LLM runtime | Ollama — Gemma 4 E4B, local GPU |
| Ollama endpoint | `http://localhost:11434/api/generate` |
| Pipeline | Python 3 (~2,200 lines across 6 scripts) |
| Interchange format | JSON |
| Resolution | 1920×1080, Forward+ renderer |

---

## Development Phase Status

| Phase | Title | Status |
|-------|-------|--------|
| 1 | Environment Setup | Complete |
| 2 | Godot 4 Foundations | Complete |
| 3 | Game State Architecture | Complete |
| 4 | LLM Pipeline (academic core) | In Progress |
| 5 | Combat & Monsters | Partial |
| 6 | Dialogue Delivery | Partial |
| 7 | Polish & Demo Prep | Pending |

---

## Implementation Notes

- **Dialogue merging:** Hard-coded role menus (sleep, shop, bounty board) merged with LLM "greeting" node at runtime in `npc_base.gd`.
- **Flag-file IPC:** Godot cannot block on a subprocess, so the pipeline writes sentinel files; SceneManager polls every 3 s.
- **Fallback chain:** LLM call fails → retry up to 3× → use pre-generated fallback JSON in `pipeline/fallbacks/`.
- **NPC memory:** Each night the LLM extracts one recollection fact and appends it to `game_state.json`. Future prompts include these facts, creating narrative persistence.
- **Day state write order:** State is written to `game_state.json` *before* the pipeline launches, so the pipeline always reads the completed day's data.
