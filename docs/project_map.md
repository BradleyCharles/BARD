# BARD — Project Map

**Game Name:** Erimentha
**Engine:** Godot 4.6 (GDScript)
**LLM Backend:** Ollama (Gemma 4 E4B, local inference)
**Pipeline Language:** Python 3
**Purpose:** Academic RPG demo — LLM-driven dynamic NPC dialogue with bounty loop

---

## Overview

BARD integrates a local LLM with a Godot 4 game. The player hunts slimes in a field, completes bounties, sleeps at an inn to end the day, and a Python pipeline generates new NPC dialogue based on game state before the next day begins. The dialogue system is the academic focus; the gameplay loop exists to feed it meaningful context.

```
Day N: hunt slimes → complete bounties → inn (end day)
     → end_of_day.py runs → NPC facts updated
     → Day N+1 dialogue written → repeat
```

---

## Directory Structure

```
BARD/
├── addons/                       # Godot plugins (currently empty)
├── archetypes/                   # NPC role templates for LLM pipeline
│   ├── blacksmith.json
│   ├── guild_commander.json
│   ├── innkeeper.json
│   ├── npc_generation_rules.json
│   ├── name_usage.json
│   └── generated/                # LLM-created NPC variants (by world_gen.py)
│       ├── blacksmith_A.json
│       ├── guild_commander_A.json
│       └── innkeeper_A.json
├── assets/                       # Sprite sheets
│   ├── Swordsman_lvl1/Without_shadow/   # Player: idle, walk, attack, hurt, death
│   ├── Slime1/Without_shadow/           # Enemy 1 (in use)
│   ├── Slime2/                          # Enemy 2 (not yet integrated)
│   └── Slime3/                          # Enemy 3 (not yet integrated)
├── autoload/
│   └── scene_manager.gd          # Global singleton: all game state + pipeline orchestration
├── data/
│   └── bounty_pool.json          # Static bounty definitions (9 entries, 3 zones × 3 tiers)
├── dialogue/                     # Generated day-specific NPC dialogue JSON
│   └── {npc_id}_day{N}.json
├── docs/
│   └── project_map.md            # This file — update when adding/removing features
├── fonts/
│   ├── almendra.regular.ttf      # Dialogue/HUD text
│   ├── almendra.bold.ttf
│   └── Xolonium-Regular.ttf     # UI labels
├── hud/                          # Legacy HUD (pre-RPG build — score UI)
│   ├── hud.gd
│   └── hud.tscn
├── main/                         # Legacy main scene (pre-RPG build)
│   ├── main.gd
│   └── main.tscn
├── mob/                          # Enemy definitions
│   ├── slime1.gd                 # Slime1 enemy AI and animation
│   ├── slime1.tscn
│   └── mob.tscn                  # Unused legacy mob scene
├── npc/                          # NPC base system
│   ├── npc_base.gd               # Proximity detection, dialogue loading/merging, wandering
│   └── npc.tscn
├── pipeline/                     # Python LLM pipeline
│   ├── config.py                 # Central config: paths, Ollama URL, model, world defs
│   ├── ollama_client.py          # Ollama HTTP wrapper with retry logic
│   ├── nl_descriptors.py         # Game state → natural language context builders
│   ├── end_of_day.py             # Main daily pipeline (called every night)
│   ├── chronicle.py              # Weekly summary + rumor generator (Ctrl+R)
│   ├── world_gen.py              # One-time setup: player name, lore, NPC variants
│   ├── fallbacks/                # Pre-generated fallback dialogue if LLM fails
│   │   ├── innkeeper_A.json
│   │   ├── blacksmith_A.json
│   │   ├── guild_commander_A.json
│   │   └── world_lore.json
│   └── lore/
│       └── thornwall.txt         # Hardcoded setting description injected into prompts
├── Player/
│   ├── player.gd                 # Movement, attack, animation, health, collision
│   └── player.tscn
├── ui/                           # All HUD and overlay UI components
│   ├── dialog_box.gd             # Typewriter effect, branching responses, dialogue actions
│   ├── dialog_box.tscn
│   ├── bounty_board.gd           # Full-screen bounty board overlay (CanvasLayer)
│   ├── bounty_board.tscn
│   ├── bounty_tracker.gd         # Passive bottom-right HUD: active bounty progress
│   ├── bounty_tracker.tscn
│   ├── bounty_turnin.gd          # Turn-in overlay: complete contracts → earn Scripts
│   ├── bounty_turnin.tscn
│   ├── health_bar.gd             # Top-left HP bar HUD (reacts to player_health_changed)
│   ├── health_bar.tscn
│   ├── scripts_hud.gd            # Top-right Scripts currency counter
│   ├── scripts_hud.tscn
│   ├── loading_screen.gd         # Overlay shown while pipeline runs
│   └── loading_screen.tscn
├── world/                        # World/scene scripts
│   ├── field.gd                  # Ashfield: bounty-zone mob spawning, kill events
│   ├── field.tscn
│   ├── bounty_board_object.gd    # World object: proximity detect → open bounty_board
│   ├── bounty_board_object.tscn
│   ├── town.gd                   # Thornwall: NPC setup from registry, dialogue reload
│   └── town.tscn
├── game_state.json               # Live game state: day, kills, bounties, flags, npc_facts
├── world_registry.json           # NPC-to-town assignments, variant IDs, display names
├── world_lore.json               # Generated world lore injected into LLM prompts
├── project.godot                 # Godot engine config
├── pipeline_ready.flag           # Sentinel: pipeline succeeded
├── pipeline_failed.flag          # Sentinel: pipeline completed with fallbacks
└── README.md
```

---

## Key Systems

### 1. SceneManager — `autoload/scene_manager.gd`

Global singleton (autoloaded). Owns all persistent game state and emits signals to UI.

**State fields:**
| Field | Type | Purpose |
|-------|------|---------|
| `day` | int | Current in-game day |
| `player_name` | String | Player character name |
| `monsters_killed_today` | Dictionary | Per-type kill counts for today |
| `monsters_killed_history` | Array[Dictionary] | Per-day kill history |
| `active_bounties` | Array | Accepted/in-progress bounties |
| `available_bounties` | Array | Bounties available on the board |
| `flags` | Dictionary | Named story/interaction flags |
| `scripts` | int | Player currency |
| `player_health` | int | Current HP (range 0–100) |

**Signals:**
| Signal | When emitted |
|--------|-------------|
| `bounties_updated` | Any bounty list change |
| `scripts_updated` | `scripts` value changed |
| `player_health_changed` | `player_health` changed |

**Public API:**
| Method | Purpose |
|--------|---------|
| `end_day()` | Increment day, archive kills, write game_state.json, show summary, launch pipeline |
| `go_to_field()` / `go_to_town()` | Scene transition with loading overlay |
| `trigger_chronicle()` | Launch chronicle.py (Ctrl+R in town) |
| `record_kill(monster_type)` | Increment `monsters_killed_today` |
| `record_bounty_kill(monster_type, zone)` | Increment bounty kill counter; mark complete when quota met |
| `accept_bounty(bounty_id)` | Move bounty from available → active |
| `turn_in_bounty(bounty_id)` | Mark turned_in, award Scripts |
| `refresh_daily_bounties()` | Repopulate available list from bounty_pool.json |
| `earn_scripts(amount)` | Add to `scripts`, emit `scripts_updated` |
| `set_player_health(hp)` | Clamp and set HP, emit `player_health_changed` |

**Pipeline handshake:** Godot launches Python via `OS.create_process()`, then polls every 3 s for `pipeline_ready.flag`, `pipeline_failed.flag`, or `pipeline_crashed.flag`. On crash a full-screen error overlay is shown.

---

### 2. Player — `Player/player.gd`

8-directional movement (WASD/arrows) clamped to world bounds set by the scene.

**Animations:** idle / idle_up / idle_down, walk / walk_up / walk_down, attack / attack_up / attack_down, hurt, death — all built from sprite-sheet atlas at runtime.

**Combat:**
- Attack: sword hitbox (`$SwordHitbox`) active on frames 2–6; emits `mob_killed(body)` signal on hit.
- Damage: `take_damage(amount)` called on mob collision; 1-second invincibility frames after hit.
- Health: `MAX_HEALTH = 100`; syncs to `SceneManager.set_player_health()` on change.
- Death: plays hurt → death animation, then emits `hit` (or `fly_caught`) to scene.

**Key signals:** `hit`, `mob_killed(mob_body)`, `fly_caught`

---

### 3. NPC Base — `npc/npc_base.gd`

Single reusable scene for all named NPCs and anonymous wanderers.

**Exports:** `npc_role`, `npc_id`, `npc_name`, `dialogue_file`, `detection_radius`, `is_wanderer`

**Dialogue loading:** Reads `dialogue/{npc_id}_day{N}.json` and merges with hardcoded role menus:
- `innkeeper`: sleep, browse shop, talk, goodbye
- `blacksmith`: browse shop, talk, goodbye
- `guild_commander`: bounty board / turn in (dynamic based on `active_bounties`), talk, goodbye

**Dialogue merging:** LLM-generated nodes are appended; hardcoded role nodes always take precedence on key collision. If no generated file exists, the "Talk" → greeting option is hidden.

**Proximity:** `DetectionArea` (Area2D) triggers dialogue open/close. `NameLabel` shown on entry.

**`reload_dialogue()`:** Reloads from `dialogue/{npc_id}_day{N}.json` without re-instantiating. Called by `SceneManager._reload_all_dialogue()` after each pipeline run.

**Wanderers:** Background NPCs with `is_wanderer = true` wander at `WANDER_SPEED = 38 px/s`, picking new direction every 2.5–6 s (30% idle chance), carrying no dialogue.

---

### 4. Dialogue Box — `ui/dialog_box.gd`

Bottom-of-screen overlay (layer 10). Added to group `dialogue_box` so NPCs can find it.

- Typewriter effect: 0.028 s/character via `TypingTimer`.
- Any key press skips to full text; number keys 1–4 select responses.
- **Built-in actions** embedded in dialogue JSON:
  - `end_day` → close box, call `SceneManager.end_day()`
  - `go_to_field` / `go_to_town` → scene transitions
  - `open_turn_in` → instantiate `bounty_turnin.tscn`

---

### 5. Bounty Board — `ui/bounty_board.gd` + `world/bounty_board_object.gd`

**BountyBoardObject** (`world/bounty_board_object.gd`): World-placed Node2D. Proximity detection (radius 140 px); shows "Press E" prompt; pressing E instantiates and opens `bounty_board.tscn`.

**BountyBoard** (`ui/bounty_board.gd`): Full-screen CanvasLayer overlay listing:
- **AVAILABLE** section: bounties from `SceneManager.available_bounties` with "Accept" button.
- **ACTIVE** section: bounties from `SceneManager.active_bounties` with In Progress / Complete badge.
- Close: `[E]` or `[Esc]`. Disables player input while open.
- Rebuilds on `SceneManager.bounties_updated` signal.

---

### 6. Bounty Tracker — `ui/bounty_tracker.gd`

Passive bottom-right HUD overlay (layer 15). Shows active/complete bounties with flavor text and kill counter. Hides when no active bounties. Rebuilds instantly on `bounties_updated`.

---

### 7. Bounty Turn-In — `ui/bounty_turnin.gd`

Opened from dialogue box (`action: "open_turn_in"` on guild commander). Lists completed contracts; click/key selects one, calls `SceneManager.turn_in_bounty()`, awards Scripts. Auto-closes when all completed bounties are turned in.

---

### 8. Health Bar — `ui/health_bar.gd`

Top-left CanvasLayer HUD. Displays `HP N / 100`. Bar fills red, turns orange below 30% HP. Reacts to `SceneManager.player_health_changed` signal.

---

### 9. Scripts HUD — `ui/scripts_hud.gd`

Top-right CanvasLayer HUD. Displays `Scripts: N`. Updates on `SceneManager.scripts_updated` signal. Scripts are the primary player currency earned by completing bounties.

---

### 10. Field Scene — `world/field.gd`

3840×2160 px playable area ("The Ashfield").

**Bounty-zone mob spawning:**
- Three zones mapped to `ColorRect` terrain nodes: `zone_a` (NW), `zone_b` (NE), `zone_c` (SE).
- On load, spawns mob count = `quantity - killed` for each active/available bounty.
- Respawn: one mob every 8 s until zone quota is filled.
- On kill: `SceneManager.record_kill()` and `SceneManager.record_bounty_kill()` called; mob freed.

**TownEntrance** (Area2D at south edge): triggers `SceneManager.go_to_town()` when player enters.

---

### 11. Town Scene — `world/town.gd`

4800×2700 px playable area ("Thornwall").

- On load: reads `world_registry.json`, assigns `npc_id` / `npc_name` to each NPC node by role, then calls `reload_all_dialogue()`.
- `FieldExit` Area2D triggers `SceneManager.go_to_field()`.
- `Ctrl+R`: triggers `SceneManager.trigger_chronicle()`.

---

### 12. Slime1 — `mob/slime1.gd`

`RigidBody2D`. Tags itself `"ground_mobs"` and `monster_type = "slime1"`.

- Wander: random direction every 1–3 s, 30% idle chance, speed 60–120 px/s.
- Bounty zone meta: `set_meta("bounty_zone", zone)` so kills register to the correct bounty.
- Boundary clamping in `_integrate_forces()`.

---

## Python Pipeline

### world_gen.py — Run Once (Initial Setup)

Prompts for player name, generates world lore via LLM, creates NPC variants, writes `world_lore.json`, `world_registry.json`, `archetypes/generated/`, and initial `game_state.json`. Then calls `end_of_day.py` to generate Day 1 dialogue.

### end_of_day.py — Runs Every Night

For each named NPC in the current town:
1. Build natural language context via `nl_descriptors.py` (kills, bounties, flags, recollections, rumors)
2. Load NPC archetype variant from `archetypes/generated/`
3. Construct LLM prompt (system + game state + world lore + NPC facts)
4. Call Ollama `/api/generate`, parse JSON dialogue tree
5. Validate schema; attempt LLM-based repair if malformed; fall back to previous day's file
6. Write `dialogue/{npc_id}_day{N}.json`
7. Generate LLM recollection fact → append to `game_state.json npc_facts`

Writes `pipeline_ready.flag` on success, `pipeline_failed.flag` on partial failure, `pipeline_crashed.flag` on unhandled exception.

### chronicle.py — Optional, Ctrl+R

Triggered from town via Ctrl+R. Generates a weekly narrative chronicle from kill history, then produces one rumor per player deed (75% named, 25% anonymous). Prunes `rumors.json` to 10 max. No day advance — player remains in town.

### nl_descriptors.py — Context Builders

Converts raw game-state fields into English prose injected into LLM prompts: kill summaries, bounty status, flags (`met_*`, `first_bounty_*`, `player_slept_at_inn`), historical trends, recollection facts, active rumors.

### ollama_client.py — LLM HTTP Wrapper

POST to `http://localhost:11434/api/generate`. Max 3 retries, 2 s delay. Streaming response parsing. Returns parsed dict or None on failure.

### config.py — Central Config

All file paths, Ollama URL, model name (overridable via env var), town/role definitions, retry settings.

---

## Bounty System — Data Flow

```
bounty_pool.json (static)
       │
SceneManager.refresh_daily_bounties()   ← called at _ready and end_day
       │ caps to min(day, 3) bounties per day
       ↓
SceneManager.available_bounties[]
       │  user clicks "Accept"
       ↓
SceneManager.active_bounties[]  (status: "active")
       │  mob killed in matching zone
       ↓
bounty["killed"]++   →  status: "complete" when killed >= quantity
       │  player opens turn-in via guild commander
       ↓
SceneManager.turn_in_bounty()   →  status: "turned_in", earn_scripts()
       │  end_day()
       ↓
active_bounties filtered (turned_in survive, others expire)
       │
game_state.json written → pipeline reads it → NPC dialogue references bounties
```

**Rewards (Scripts):**
| Bounty tier (id suffix) | Reward |
|------------------------|--------|
| `_small` | 10 Scripts |
| `_medium` | 25 Scripts |
| `_large` | 50 Scripts |

---

## Data Formats

### game_state.json

```json
{
  "meta": {"schema_version": "1.0", "day": 1},
  "player_name": "Hunter",
  "scripts": 35,
  "world_state": {
    "monsters_killed_today": {"slime1": 5},
    "monsters_killed_history": [{"slime1": 3}]
  },
  "available_bounties": [],
  "active_bounties": [
    {
      "id": "slime1_zone_a_small", "monster_type": "slime1",
      "zone": "zone_a", "quantity": 5, "killed": 5,
      "status": "complete", "day_accepted": 1
    }
  ],
  "flags": {"met_yara_varen": false, "first_bounty_accepted": true},
  "npc_facts": {
    "yara_varen": {
      "facts": [{"text": "...", "added_day": 1, "weight": "recent", "source": "llm"}]
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
      "text": "Safe return, hunter.",
      "responses": [{"text": "Just resting.", "next": "farewell", "key": 1}]
    },
    "farewell": {
      "text": "Rest well.",
      "responses": [{"text": "Good night.", "next": null, "key": 1, "action": "end_day"}]
    }
  }
}
```

### world_registry.json

```json
{
  "schema_version": "1.0",
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

### bounty_pool.json

```json
{
  "bounties": [
    {
      "id": "slime1_zone_a_small", "monster_type": "slime1",
      "zone": "zone_a", "quantity": 5,
      "flavor": "A small number of oozing creatures...",
      "reward_text": "5 gold upon verified completion."
    }
  ]
}
```

---

## Technology Stack

| Component | Technology |
|-----------|-----------|
| Game engine | Godot 4.6, GDScript |
| LLM runtime | Ollama — Gemma 4 E4B, local GPU |
| Ollama endpoint | `http://localhost:11434/api/generate` |
| Pipeline | Python 3 |
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
| 6 | Dialogue Delivery & Bounty Board | Partial |
| 7 | Polish & Demo Prep | Pending |

---

## Implementation Notes

- **Dialogue merging:** Hard-coded role menus (sleep, shop, bounty board) merged with LLM "greeting" node at runtime in `npc_base.gd`. LLM generates the "greeting" node and conversational branches only.
- **Flag-file IPC:** Godot cannot block on a subprocess, so the pipeline writes sentinel files; SceneManager polls every 3 s (180 s timeout).
- **Fallback chain:** LLM call fails → retry up to 3× → LLM-based JSON repair → previous day's dialogue file → `pipeline/fallbacks/`.
- **NPC memory:** Each night the LLM extracts one recollection fact and appends it to `game_state.npc_facts`. Future prompts include these facts, creating narrative persistence.
- **Day state write order:** State is written to `game_state.json` *before* the pipeline launches, so the pipeline always reads the completed day's data.
- **Bounty zones:** Zones `zone_a/b/c` map 1-to-1 to `TerrainNW/NE/SE` ColorRect nodes in `field.tscn`. Mob meta tag `bounty_zone` links kills to the correct bounty entry.
- **Guild commander patch:** `npc_base.gd:_patch_guild_commander_root()` dynamically replaces the first response option with "I have completed a bounty" if any bounty has `status == "complete"`, enabling the turn-in flow without changing the LLM dialogue.
- **Scripts currency:** Scripts are the player's only currency. Earned by turning in bounties. Displayed top-right. Not yet spendable (future phase).

---

*Update this file whenever a component, scene, script, or feature is added, removed, or significantly refactored.*
