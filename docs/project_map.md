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
│   ├── Slime1/Without_shadow/           # Enemy 1: individual PNGs per frame (idle_down0–5, etc.)
│   ├── Slime2/                          # Enemy 2: spritesheet — Idle 384×256, Walk 512×256, 64px, 4 rows
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
│   ├── mob_base.gd               # Shared base (extends RigidBody2D): health, take_damage, died signal, AI state machine
│   ├── slime1.gd                 # Slime1: WEAK_AGGRESSIVE AI (chases when player < 150px), HP=1
│   ├── slime1.tscn
│   ├── slime1_elite.gd           # Elite slime: HP=5, aggro=200px, purple tint, 10% Slime Goop drop
│   ├── slime1_elite.tscn
│   ├── slime1_boss.gd            # Boss slime: HP=10, always chases, red 5× scale, 100% drop (5 goop)
│   ├── slime1_boss.tscn
│   ├── slime2.gd                 # Slime2: PACK_MENTALITY (flees alone; attacks in groups of 3+)
│   ├── slime2.tscn
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
│   ├── scripts_hud.gd            # Top-right Scripts + Slime Goop counter
│   ├── scripts_hud.tscn
│   ├── weapon_hud.gd             # Bottom-center weapon slots (active/locked states)
│   ├── weapon_hud.tscn
│   ├── boss_health_bar.gd        # Top-center boss HP bar (shown when boss is alive)
│   ├── boss_health_bar.tscn
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
| `scripts` | int | Player currency (primary) |
| `slime_goop` | int | Rare drop currency (from elite/boss slimes) |
| `owned_weapons` | Array | Weapon IDs owned by the player (default: `["sword"]`) |
| `weapon_upgrades` | Dictionary | Upgrade tier per weapon ID |
| `player_health` | int | Current HP (range 0–100) |

**Signals:**
| Signal | When emitted |
|--------|-------------|
| `bounties_updated` | Any bounty list change |
| `scripts_updated` | `scripts` or `slime_goop` value changed |
| `player_health_changed` | `player_health` changed |
| `inventory_updated` | `owned_weapons`, `weapon_upgrades`, or `slime_goop` changed |

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
| `earn_slime_goop(amount)` | Add to `slime_goop`, emit `inventory_updated` |
| `buy_weapon(id, cost)` | Deduct Scripts, append to `owned_weapons`; no-op if already owned |
| `upgrade_weapon(id, cost_scripts, cost_goop)` | Deduct Scripts + Goop, increment `weapon_upgrades[id]` |
| `set_player_health(hp)` | Clamp and set HP, emit `player_health_changed` |

**Pipeline handshake:** Godot launches Python via `OS.create_process()`, then polls every 3 s for `pipeline_ready.flag`, `pipeline_failed.flag`, or `pipeline_crashed.flag`. On crash a full-screen error overlay is shown.

---

### 2. Player — `Player/player.gd`

8-directional movement (arrow keys / WASD, left stick) clamped to world bounds set by the scene.

**Animations:** idle / idle_up / idle_down, walk / walk_up / walk_down, attack / attack_up / attack_down, hurt, death — all built from sprite-sheet atlas at runtime.

**Combat:**
- Attack: `A` key / gamepad West (X) button; sword hitbox (`$SwordHitbox`) active on frames 2–6.
- On hit: calls `body.take_damage(damage, knockback_vec)` on the mob directly.
- Damage: `take_damage(amount)` called on mob collision; 1-second invincibility frames after hit.
- Health: `MAX_HEALTH = 100`; syncs to `SceneManager.set_player_health()` on change.
- Death: plays hurt → death animation, then emits `hit` (or `fly_caught`) to scene.

**Dodge:** Space / gamepad East (B) button. 0.3 s dash at 900 px/s. Full iframes during dash. 0.8 s cooldown. Player is semi-transparent while dodging.

**Weapon system:**
- `WEAPON_STATS`: sword (damage=1, 20 FPS swing, 200 knockback) and axe (damage=2, 12 FPS, 400 knockback).
- `active_weapon`: default "sword". Q key / gamepad North (Y) button cycles owned weapons.
- Attack animation speed and hitbox size are set from active weapon stats at attack start.
- `weapon_changed(weapon_name)` signal emitted on swap.

**`set_gameplay_active(enabled: bool)`:** Freezes/unfreezes `_process` and `_input` together. Called by UI overlays (dialogue, bounty board, turn-in) to prevent movement while menus are open.

**Key signals:** `hit`, `fly_caught`, `weapon_changed(weapon_name: String)`

---

### 3. NPC Base — `npc/npc_base.gd`

Single reusable scene for all named NPCs and anonymous wanderers.

**Exports:** `npc_role`, `npc_id`, `npc_name`, `dialogue_file`, `detection_radius`, `is_wanderer`

**Interaction model (press-to-talk):** `DetectionArea` proximity shows the NPC name label and a `[A] Talk` prompt. Dialogue does NOT auto-open on approach. The player presses `interact` (A / E) to open dialogue. Walking away while dialogue is open closes it automatically. Prompt re-appears when dialogue closes if player is still in range.

**Dialogue loading:** Reads `dialogue/{npc_id}_day{N}.json` and merges with hardcoded role menus:
- `innkeeper`: sleep, browse shop, talk, goodbye
- `blacksmith`: browse wares, upgrade weapons (dynamic shop), talk, goodbye
- `guild_commander`: bounty board / turn in (dynamic based on `active_bounties`), talk, goodbye

**Blacksmith upgrade menu** (`_patch_blacksmith_root()`): Dynamically adjusts the `upgrade_menu` node based on `SceneManager.owned_weapons`. Shows "Buy Axe" only if not yet owned; shows "Upgrade Sword/Axe" only for owned weapons. Dialogue actions: `buy_axe`, `upgrade_sword`, `upgrade_axe`.

**Dialogue merging:** LLM-generated nodes are appended; hardcoded role nodes always take precedence on key collision. If no generated file exists, the "Talk" → greeting option is hidden.

**`reload_dialogue()`:** Reloads from `dialogue/{npc_id}_day{N}.json` without re-instantiating. Called by `SceneManager._reload_all_dialogue()` after each pipeline run.

**Wanderers:** Background NPCs with `is_wanderer = true` wander at `WANDER_SPEED = 38 px/s`, picking new direction every 2.5–6 s (30% idle chance), carrying no dialogue.

---

### 4. Dialogue Box — `ui/dialog_box.gd`

Fixed-size (1000×292 px) bottom-center overlay (layer 10). Added to group `dialogue_box` so NPCs can find it. Dark parchment palette matching all other UI overlays.

- Typewriter effect: 0.028 s/character via `TypingTimer`.
- Any key / button press skips to full text.
- D-pad ↑↓ / arrow keys navigate responses; selected response shown in gold with a 2 px underline; others dimmed.
- `interact` (A / E) confirms selected response.
- Locks player `_process` and `_input` on `open()`, restores on `close()`.
- **Built-in actions** embedded in dialogue JSON:
  - `end_day` → close box, call `SceneManager.end_day()`
  - `go_to_field` / `go_to_town` → scene transitions
  - `open_turn_in` → instantiate `bounty_turnin.tscn`
  - `buy_axe` → 50 Scripts; `upgrade_sword` → 100 Scripts + 5 Goop; `upgrade_axe` → 150 Scripts + 10 Goop
  - Insufficient funds shows a transient `_insufficient_funds` node injected at `open()` time

---

### 5. Bounty Board — `ui/bounty_board.gd` + `world/bounty_board_object.gd`

**BountyBoardObject** (`world/bounty_board_object.gd`): World-placed Node2D. Proximity detection (radius 140 px); shows `[A] Bounty Board` prompt; `interact` (A / E) instantiates and opens `bounty_board.tscn`.

**BountyBoard** (`ui/bounty_board.gd`): Full-screen CanvasLayer overlay (dark parchment palette) listing:
- **AVAILABLE** section: D-pad ↑↓ navigates; selected row highlighted in gold with 2 px underline; `interact` (A / E) accepts. No buttons.
- **ACTIVE** section: display-only with In Progress / Complete badge.
- Close: `menu_cancel` (B / Esc). Freezes player while open via `set_gameplay_active(false)`.
- Rebuilds on `SceneManager.bounties_updated` signal.

---

### 6. Bounty Tracker — `ui/bounty_tracker.gd`

Passive bottom-right HUD overlay (layer 15). Shows active/complete bounties with flavor text and kill counter. Hides when no active bounties. Rebuilds instantly on `bounties_updated`.

---

### 7. Bounty Turn-In — `ui/bounty_turnin.gd`

Opened from dialogue box (`action: "open_turn_in"` on guild commander). Lists completed contracts; D-pad ↑↓ navigates, selected row in gold with 2 px underline, `interact` (A / E) turns in and awards Scripts. `menu_cancel` (B / Esc) closes. Auto-closes when all completed bounties are turned in.

---

### 8. Health Bar — `ui/health_bar.gd`

Top-left CanvasLayer HUD. Displays `HP N / 100`. Bar fills red, turns orange below 30% HP. Reacts to `SceneManager.player_health_changed` signal.

---

### 9. Scripts HUD — `ui/scripts_hud.gd`

Top-right CanvasLayer HUD. Displays `Scripts: N` (27 pt). When `SceneManager.slime_goop > 0`, also shows a purple `Goop: N` label (20 pt) below. Updates on both `scripts_updated` and `inventory_updated` signals.

---

### 10. Field Scene — `world/field.gd`

3840×2160 px playable area ("The Ashfield").

**Camera:** Zoomed 1.5× in `_ready()`. Limits clamped to world edges so the player cannot push the camera into void (half-viewport = 640×360 px at 1.5× zoom).

**Bounty-zone mob spawning:**
- Three zones mapped to `ColorRect` terrain nodes: `zone_a` (NW), `zone_b` (NE), `zone_c` (SE).
- On load, spawns mob count = `quantity - killed` for each active/available bounty.
- Respawn: one mob every 8 s until zone quota is filled.
- 10% of `slime1` spawns are replaced with `slime1_elite` (if `slime1_elite_scene` export is assigned).
- Each spawned mob's `died` signal is connected to `_on_mob_died()`.
- On kill: `SceneManager.record_kill()` and `SceneManager.record_bounty_kill()` called; mob frees itself.

**Boss trigger:**
- `_boss_threshold` = `randi_range(19, 20)` set in `_ready()`.
- After `_slimes_killed` reaches the threshold, `_spawn_boss()` fires once.
- Boss spawns at world center; `boss_health_bar.tscn` is instantiated and `init(boss)` called.
- `@export var slime1_elite_scene: PackedScene` and `@export var slime2_scene: PackedScene` must be assigned in the Godot editor inspector after the .tscn files exist.

**TownEntrance** (Area2D at south edge): triggers `SceneManager.go_to_town()` when player enters.

---

### 11. Town Scene — `world/town.gd`

4800×2700 px playable area ("Thornwall").

**Camera:** Zoomed 1.5× in `_ready()`, limits clamped to world edges (half-viewport = 640×360 px).

- On load: reads `world_registry.json`, assigns `npc_id` / `npc_name` to each NPC node by role, then calls `reload_all_dialogue()`.
- `FieldExit` Area2D triggers `SceneManager.go_to_field()`.
- `Ctrl+R`: triggers `SceneManager.trigger_chronicle()`.

---

### 12. Mob Base — `mob/mob_base.gd`

Base class (extends `RigidBody2D`) for all enemy types.

**Enums:**
- `Personality`: `WANDER`, `WEAK_AGGRESSIVE`, `PACK_MENTALITY`, `BOSS`
- `AIState`: `WANDER_STATE`, `CHASE_STATE`, `FLEE_STATE`

**Exports:** `max_health`, `personality`, `aggro_radius`, `pack_radius`, `pack_threshold`

**Key methods:**
- `take_damage(amount, knockback_vec)`: decrement health, apply impulse, flash red for 0.15 s, call `_on_died()` if health ≤ 0
- `_on_died()`: emit `died(self)`, call `queue_free()`
- `_direction_to_player_with_noise(speed)`: normalized direction to player with ±15° sine noise × speed
- `_distance_to_player()`: returns INF if no player ref found

**Signal:** `died(mob: Node)` — connected by `field.gd` at spawn time.

`_ready()` adds mob to group `"ground_mobs"` and finds the player reference.

---

### 13. Slime1 — `mob/slime1.gd`

Extends `mob_base`. `max_health=1`, `personality=WEAK_AGGRESSIVE`, `aggro_radius=150`.

- Wander: random direction every 1–3 s, 30% idle chance, speed 60–120 px/s.
- AI: chases player when within `aggro_radius`; wander resumes on exit.
- Bounty zone meta: `set_meta("bounty_zone", zone)` so kills register to the correct bounty.
- Boundary clamping in `_integrate_forces()`.

---

### 14. Slime1 Elite — `mob/slime1_elite.gd`

Extends `slime1`. `max_health=5`, `aggro_radius=200`. Purple tint (`Color(0.7, 0.5, 1.0)`). 10% chance to drop 1 Slime Goop on death. Spawns at ~10% of normal slime1 spawn sites.

---

### 15. Slime1 Boss — `mob/slime1_boss.gd`

Extends `mob_base`. `max_health=10`, `personality=BOSS`, always chases. Red tint, 5× scale, 150 px/s. Drops 5 Slime Goop guaranteed on death. Spawns at world center after 19–20 slime kills. Has `_integrate_forces` boundary clamping (MOB_RADIUS=50).

---

### 16. Slime2 — `mob/slime2.gd`

Extends `mob_base`. `max_health=2`, `personality=PACK_MENTALITY`. Uses AtlasTexture spritesheet (`Slime2_Idle_without_shadow.png` 384×256, `Slime2_Walk_without_shadow.png` 512×256, 64 px frames, 4 rows: 0=Down, 1=Left, 2=Right, 3=Up).

- Alone (pack < 3): flees from player when within aggro range.
- In pack (≥ 3 slime2 within 200 px): chases player.
- `_count_nearby_pack()` counts `"slime2"`-tagged mobs in `"ground_mobs"` group within `pack_radius`.

---

### 17. Weapon HUD — `ui/weapon_hud.gd`

Bottom-center CanvasLayer (layer 6). Two slots: sword, axe. Built entirely in code.

- **Active**: gold border (3 px) + gold label text.
- **Owned inactive**: normal border + gold text.
- **Locked** (not owned): dim border + grey text + ` [lock]` suffix.
- Connects to `SceneManager.inventory_updated` and player's `weapon_changed` signal (deferred lookup via group `"player"`).

---

### 18. Boss Health Bar — `ui/boss_health_bar.gd`

Top-center CanvasLayer (layer 20). Shown only while boss is alive.

- `init(boss: Node)`: stores ref, connects `boss.died → _on_boss_died`, shows bar.
- Updates every frame: 600 px wide fill rect scales by `health / max_health`; label shows `BOSS N / 10`.
- On boss death: hides and `queue_free()`s itself.
- Colors: dark bg, red fill, gold label text.

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

## Input Map

| Action | Keyboard | Controller |
|--------|----------|------------|
| `move_up/down/left/right` | Arrow keys | Left stick |
| `attack` | A | West button (X) |
| `dodge` | Space | East button (B) |
| `weapon_swap` | Q | North button (Y) |
| `interact` | E | South button (A) |
| `menu_up` | Up arrow | D-pad up |
| `menu_down` | Down arrow | D-pad down |
| `menu_cancel` | Escape | East button (B) |

`interact` is the universal "do thing" action: open NPC dialogue, open bounty board, confirm menu selections.
`menu_cancel` shares the East button with `dodge`; player process is frozen while any menu is open so there is no conflict.

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
