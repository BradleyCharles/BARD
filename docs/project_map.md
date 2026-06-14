# BARD — Project Map

**Game Name:** Erimentha
**Engine:** Godot 4.6 (GDScript)
**LLM Backend:** Ollama (Gemma 4 E4B, local inference)
**Pipeline Language:** Python 3
**Purpose:** Academic RPG demo — LLM-driven dynamic NPC dialogue with bounty loop

---

## Overview

BARD integrates a local LLM with a Godot 4 game. The player hunts mobs (slimes in zone_c, orcs and plants in zone_a, vampires in zone_b) in the field, completes bounties, sleeps at an inn to end the day, and a Python pipeline generates new NPC dialogue based on game state before the next day begins. The dialogue system is the academic focus; the gameplay loop exists to feed it meaningful context.

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
├── assets/                       # Sprite sheets and animation sources
│   ├── Swordsman_lvl1/           # Wandering NPC sprites (.aseprite per direction)
│   │   ├── Swordsman_lvl1_Idle/          # front/back/side_left/side_right
│   │   ├── Swordsman_lvl1_Walk/
│   │   ├── Swordsman_lvl1_Walk_attack/
│   │   ├── Swordsman_lvl1_Run/
│   │   ├── Swordsman_lvl1_Run_attack/
│   │   ├── Swordsman_lvl1_Attack/
│   │   ├── Swordsman_lvl1_Hurt/
│   │   └── Swordsman_lvl1_Death/
│   ├── Swordsman_lvl2/           # Named NPC sprites (innkeeper, blacksmith, guild master) — same layout as lvl1
│   ├── Swordsman_lvl3/           # Player sprites — same layout as lvl1
│   ├── Sword/                    # Sword attack animation: individual PNGs 1.png–8.png
│   ├── Axe/                      # Axe attack animation: individual PNGs 1.png–10.png
│   ├── Bounty_Board/             # Bounty board world object sprites
│   └── mobs/                     # All mob sprite sheets (.aseprite per animation/direction)
│       ├── Slime1/               # slime1 and slime3_boss assets
│       ├── Slime2/               # slime2 assets
│       ├── Slime3/               # slime3 and slime3_boss assets
│       ├── Orc1/ Orc2/ Orc3/    # orc1/2/3 and orc3_boss assets
│       ├── Plant1/ Plant2/ Plant3/  # plant1/2/3 and plant3_boss assets
│       └── Vampire1/ Vampire2/ Vampire3/  # vampire1/2/3 and vampire3_boss assets
├── autoload/
│   └── scene_manager.gd          # Global singleton: all game state + pipeline orchestration
├── data/
│   └── bounty_pool.json          # Static bounty definitions (36 entries: zone_c slimes × 9, zone_a orcs+plants × 18, zone_b vampires × 9)
├── dialogue/                     # Generated day-specific NPC dialogue JSON
│   └── {npc_id}_day{N}.json
├── docs/
│   ├── project_map.md            # Directory, scripts, constants — update on structural changes
│   ├── game_mechanics.md         # Collision layers, damage flow, mob AI rules
│   └── game_systems.md           # End-to-end system flows (pipeline, bounties, dialogue, etc.)
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
│   ├── mob_stats.gd              # All mob tuning constants (HP, dmg, speed, hitbox, AI radii) — grouped by family, bosses last
│   ├── mob_base.gd               # Shared base (extends RigidBody2D): health, take_damage, died signal, AI state machine
│   ├── slime1.gd / .tscn         # Slime1: PACK_MENTALITY, HP=3, zone_c, flees alone, links pack on 2+ nearby
│   ├── slime2.gd / .tscn         # Slime2: PACK_MENTALITY, HP=6, zone_c, passive until hit
│   ├── slime3.gd / .tscn         # Slime3: WEAK_AGGRESSIVE, HP=8, zone_c, chases on sight
│   ├── slime3_boss.gd / .tscn    # Slime3 Boss: HP=30, AOE attack, drops 20 Goop — spawns after 10 combined slime kills
│   ├── orc1.gd / .tscn           # Orc1: charger AI, HP=8, dmg=2, zone_a
│   ├── orc2.gd / .tscn           # Orc2: charger AI, HP=14, dmg=3, zone_a
│   ├── orc3.gd / .tscn           # Orc3: charger AI, HP=22, dmg=4, zone_a
│   ├── orc3_boss.gd / .tscn      # Orc3 Boss: HP=60, telegraphed charge, drops 15 Goop — after 10 orc kills
│   ├── plant1.gd / .tscn         # Plant1: creeper AI, HP=10, dmg=2, zone_a
│   ├── plant2.gd / .tscn         # Plant2: creeper AI, HP=18, dmg=3, zone_a
│   ├── plant3.gd / .tscn         # Plant3: creeper AI, HP=28, dmg=5, zone_a
│   ├── plant3_boss.gd / .tscn    # Plant3 Boss: HP=50, starburst AOE, drops 15 Goop — after 10 plant kills
│   ├── vampire1.gd / .tscn       # Vampire1: stalker AI, HP=6, dmg=1, zone_b
│   ├── vampire2.gd / .tscn       # Vampire2: stalker AI, HP=10, dmg=2, zone_b
│   ├── vampire3.gd / .tscn       # Vampire3: stalker AI, HP=16, dmg=3, zone_b
│   ├── vampire3_boss.gd / .tscn  # Vampire3 Boss: HP=40, orbit+life drain, drops 15 Goop — after 10 vampire kills
│   ├── mob_demo.gd               # Testing-only display mob: idle sprite + hitbox circle, no AI/physics
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
│   ├── player1/
│   │   ├── player.gd             # Movement, attack, animation, health, collision
│   │   ├── player_stats.gd       # Tuning constants: MAX_HEALTH, dodge timing, BASE_SPEED
│   │   ├── player_input.gd       # Input action name constants (class_name PlayerInput)
│   │   └── player.tscn
│   └── weapons/
│       ├── sword_data.gd         # Sword: DAMAGE=1, SWING_FPS=40, KNOCKBACK=200, HITBOX
│       └── axe_data.gd           # Axe: DAMAGE=2, SWING_FPS=24, KNOCKBACK=400, HITBOX
├── ui/                           # All HUD and overlay UI components
│   ├── dialog_box.gd             # Typewriter effect, branching responses, dialogue actions
│   ├── dialog_box.tscn
│   ├── bounty_board.gd           # Full-screen bounty board overlay (CanvasLayer)
│   ├── bounty_board.tscn
│   ├── pause_bounty_screen.gd    # Pause-menu sub-screen: view/drop active bounties
│   ├── bounty_tracker.gd         # Passive bottom-right HUD: active bounty progress
│   ├── bounty_tracker.tscn
│   ├── bounty_turnin.gd          # Turn-in overlay: complete contracts → earn Scripts
│   ├── bounty_turnin.tscn
│   ├── health_bar.gd             # Top-left HP bar HUD (reacts to player_health_changed)
│   ├── health_bar.tscn
│   ├── scripts_hud.gd            # Top-right Scripts + Slime Goop counter
│   ├── scripts_hud.tscn
│   ├── weapon_hud.gd             # Top-center weapon slots (active/locked states)
│   ├── weapon_hud.tscn
│   ├── boss_health_bar.gd        # Top-center boss HP bar (shown when boss is alive)
│   ├── boss_health_bar.tscn
│   ├── boss_tracker.gd           # Bottom-left boss summon tracker HUD (field only; instantiated by field.gd)
│   ├── minimap.gd                # Bottom-right minimap (field scene only; instantiated by field.gd)
│   ├── teleport_menu.gd          # Testing-only teleport menu (SELECT key; instantiated by field.gd when testing_mode ON)
│   ├── loading_screen.gd         # Overlay shown while pipeline runs
│   ├── loading_screen.tscn
│   └── game_over_screen.gd       # Full-screen GAME OVER overlay (CanvasLayer, layer 200)
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
| `testing_mode` | bool | When true, field spawns all mobs for testing; bypasses bounty spawning |
| `owned_weapons` | Array | Weapon IDs owned by the player (default: `["sword", "axe"]`) |
| `weapon_upgrades` | Dictionary | Upgrade tier per weapon ID |
| `player_health` | int | Current HP (range 0–100) |

**Signals:**
| Signal | When emitted |
|--------|-------------|
| `bounties_updated` | Any bounty list change |
| `scripts_updated` | `scripts` or `slime_goop` value changed |
| `player_health_changed` | `player_health` changed |
| `inventory_updated` | `owned_weapons`, `weapon_upgrades`, or `slime_goop` changed |
| `day_updated` | `day` incremented at end_day |
| `testing_mode_changed(enabled: bool)` | Emitted when testing_mode toggled via pause menu |

**Public API:**
| Method | Purpose |
|--------|---------|
| `end_day()` | Increment day, archive kills, write game_state.json, show summary, launch pipeline |
| `go_to_field()` / `go_to_town()` | Scene transition with loading overlay |
| `trigger_chronicle()` | Launch chronicle.py (Ctrl+R in town) |
| `record_kill(monster_type)` | Increment `monsters_killed_today` |
| `record_bounty_kill(monster_type, zone)` | Increment bounty kill counter; mark complete when quota met |
| `accept_bounty(bounty_id)` | Move bounty from available → active |
| `drop_bounty(bounty_id)` | Remove from active, restore fresh copy to available (resets progress) |
| `turn_in_bounty(bounty_id)` | Mark turned_in, award Scripts |
| `refresh_daily_bounties()` | Repopulate available list from bounty_pool.json |
| `earn_scripts(amount)` | Add to `scripts`, emit `scripts_updated` |
| `earn_slime_goop(amount)` | Add to `slime_goop`, emit `inventory_updated` |
| `set_testing_mode(enabled)` | Set `testing_mode`, emit `testing_mode_changed` |
| `buy_weapon(id, cost)` | Deduct Scripts, append to `owned_weapons`; no-op if already owned |
| `upgrade_weapon(id, cost_scripts, cost_goop)` | Deduct Scripts + Goop, increment `weapon_upgrades[id]` |
| `set_player_health(hp)` | Clamp and set HP, emit `player_health_changed` |

**Pipeline handshake:** Godot launches Python via `OS.create_process()`, then polls every 3 s for `pipeline_ready.flag`, `pipeline_failed.flag`, or `pipeline_crashed.flag`. On crash a full-screen error overlay is shown.

---

### 2. Player — `Player/player.gd`

8-directional movement (arrow keys / WASD, left stick) clamped to world bounds set by the scene.

**Animations:** idle / idle_up / idle_down, walk / walk_up / walk_down, run / run_up / run_down, attack / attack_up / attack_down, hurt, death. Source: `assets/Swordsman_lvl3/` (.aseprite files, one per direction: front/back/side_left/side_right), loaded at runtime via `_build_sprite_frames()`. Weapon swing overlays come from `assets/Sword/` (1–8 PNGs) and `assets/Axe/` (1–10 PNGs).

**State machine:** `PlayerState` enum — `IDLE`, `MOVE`, `ATTACK`, `HURT`, `DODGE`, `DEAD`. Transitioned via `_set_state()` which keeps legacy booleans (`is_attacking`, `_is_hurt`, `is_dodging`) in sync.

**Combat:**
- Attack: `A` key / gamepad West (X) button. Direction snapped to 8 directions (every 45°). SwordHitbox rotated to match attack direction; active on frames 2–6.
- Input Buffer: 0.15 s window (`_attack_buffer`) queues a second attack during a swing; fires at the end of the current animation.
- Movement during attack: Sword 40% speed (`MOVE_MODIFIER = 0.4`), Axe full stop (`MOVE_MODIFIER = 0.0`).
- On hit: `body.take_damage(damage, knockback_vec)`, then impact particles spawned, `attack_connected` signal emitted, hitstop applied.
- Hit Stop: `Engine.time_scale = 0` for Sword 0.05 s / Axe 0.12 s using unscaled timer.
- Damage: `take_damage(amount)` → `PlayerState.HURT`; 1-second invincibility frames.
- Health: defined in `PlayerStats.MAX_HEALTH`; syncs to `SceneManager.set_player_health()` on change.
- Death: plays hurt → death animation, then emits `hit` (or `fly_caught`) to scene.

**New signal:** `attack_connected(weapon_id: String, hit_point: Vector2, attack_dir: Vector2)` — emitted on every successful hit; `field.gd` connects to it for camera shake.

**Dodge:** Space / gamepad East (B) button. Duration/speed/cooldown defined in `PlayerStats`. Full iframes during dash. Player is semi-transparent while dodging.

**Run:** Hold the Run button (mapped to the `roll` input action). Multiplies movement speed by `PlayerStats.RUN_SPEED_MULTIPLIER` (1.25×) while held. No cooldown or timer — active only when button is held and player is not attacking or dodging.

**Weapon system:**
- Weapon data lives in `Player/weapons/sword_data.gd` and `axe_data.gd`. `player.gd` builds `_weapon_stats` from these in `_ready()`.
- `active_weapon`: default `SwordData.ID`. Q key / gamepad North (Y) button cycles owned weapons.
- Attack animation speed and hitbox size are set from active weapon stats at attack start.
- `weapon_changed(weapon_name)` signal emitted on swap.
- To add a new weapon: create `Player/weapons/<name>_data.gd` and add an entry in `player.gd:_ready()`.

**`set_gameplay_active(enabled: bool)`:** Freezes/unfreezes `_process` and `_input` together. Called by UI overlays (dialogue, bounty board, turn-in) to prevent movement while menus are open.

**Key signals:** `hit`, `fly_caught`, `weapon_changed(weapon_name: String)`

---

### 2a. PlayerStats — `Player/player_stats.gd`

All player balance constants in one file. Edit here for tuning.

| Constant | Value | Purpose |
|----------|-------|---------|
| `MAX_HEALTH` | 100 | Starting and max HP |
| `IFRAME_TIME` | 1.0 s | Invincibility duration after hit or dodge |
| `BASE_SPEED` | 150.0 px/s | Default movement speed (also `@export` default in player.gd) |
| `DODGE_SPEED` | 900.0 px/s | Velocity during a dodge |
| `DODGE_DURATION` | 0.15 s | How long a single dodge lasts |
| `DODGE_COOLDOWN` | 0.5 s | Minimum time between dodges |
| `RUN_SPEED_MULTIPLIER` | 10 | Speed multiplier applied while Run is held |
| `KNOCKBACK_DURATION` | 0.30 s | How long player knockback velocity is applied |

---

### 2b. PlayerInput — `Player/player_input.gd`

Centralizes all input action name strings. Use `PlayerInput.ATTACK` etc. everywhere — never bare string literals like `"attack"`. Changing an action name requires updating only this file.

| Constant | Action |
|----------|--------|
| `MOVE_UP/DOWN/LEFT/RIGHT` | Arrow keys / left stick |
| `ATTACK` | A / West button |
| `DODGE` | Space / East button |
| `RUN` | Roll button (held) |
| `INTERACT` | E / South button |
| `WEAPON_SWAP` | Q / North button |
| `MENU_UP/DOWN` | Arrow keys / D-pad |
| `MENU_CANCEL` | Escape / East button |
| `SELECT` | Tab / controller Back button (opens teleport menu in field when testing_mode ON) |

---

### 2c. Weapon Data — `Player/weapons/`

Each weapon is a GDScript file with `class_name` and typed constants. Use `sword_data.gd` as the template when adding a new weapon.

| File | ID | DAMAGE | SWING_FPS | KNOCKBACK | HITBOX | HITBOX_OFFSET | MOVE_MODIFIER | HITSTOP | SHAKE_INTENSITY | SHAKE_DURATION | SHAKE_FREQUENCY |
|------|----|--------|-----------|-----------|--------|---------------|---------------|---------|-----------------|----------------|-----------------|
| `sword_data.gd` | `"sword"` | 3 | 30.0 | 100.0 | 60×40 px | 30.0 px | 0.4 (40%) | 0.05 s | 3.0 | 0.12 s | 200.0 |
| `axe_data.gd` | `"axe"` | 6 | 15.0 | 200.0 | 35×70 px | 45.0 px | 0.0 (stop) | 0.12 s | 8.0 | 0.22 s | 80.0 |

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

**Wanderers:** Background NPCs with `is_wanderer = true` wander at `WANDER_SPEED = 38 px/s`, picking new direction every 2.5–6 s (30% idle chance), carrying no dialogue. Use `assets/Swordsman_lvl1/` sprites.

**Sprite assignment by NPC type:**
- Wanderers → `assets/Swordsman_lvl1/` (idle animations: front/back/side_right)
- Named NPCs (innkeeper, blacksmith, guild master) → `assets/Swordsman_lvl2/` (same layout)

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

Passive top-right HUD overlay (layer 15). Shows active/complete bounties with flavor text and kill counter. Hides when no active bounties. Rebuilds instantly on `bounties_updated`.

---

### 7. Bounty Turn-In — `ui/bounty_turnin.gd`

Opened from dialogue box (`action: "open_turn_in"` on guild commander). Lists completed contracts; D-pad ↑↓ navigates, selected row in gold with 2 px underline, `interact` (A / E) turns in and awards Scripts. `menu_cancel` (B / Esc) closes. Auto-closes when all completed bounties are turned in.

---

### 8. Health Bar — `ui/health_bar.gd`

Top-left CanvasLayer HUD. Displays `HP N / 100`. Bar fills red, turns orange below 30% HP. Reacts to `SceneManager.player_health_changed` signal.

---

### 9. Scripts HUD — `ui/scripts_hud.gd`

Top-left CanvasLayer HUD, below the health bar (offset_top 90). Displays `Scripts: N` (27 pt). When `SceneManager.slime_goop > 0`, also shows a purple `Goop: N` label (20 pt) below. Updates on both `scripts_updated` and `inventory_updated` signals.

---

### 10. Field Scene — `world/field.gd`

3840×2160 px playable area ("The Ashfield").

**Camera:** Zoomed 3.5× in `_ready()`. Limits clamped to world edges via `BoundaryLeft/Right/Top/Bottom` ColorRect nodes (playable area ~x 349–6285, y 350–4096).

**Bounty-zone mob spawning:**
- Three zones mapped to `ColorRect` terrain nodes: `zone_a` (NE, node `TerrainNW`), `zone_b` (SE, node `TerrainNE`), `zone_c` (SW, node `TerrainSE`). Note: scene node names are misnamed — the actual quadrant positions are NE, SE, and SW; the NW quadrant has no zone. `zone_a` maps to `_terrain_nw` in code, etc.
- On load, spawns mob count = `quantity - killed` for each active/available bounty.
- Respawn: one mob every 8 s until zone quota is filled.
- Each spawned mob's `died` signal is connected to `_on_mob_died()`.
- On kill: `SceneManager.record_kill()` and `SceneManager.record_bounty_kill()` called; mob frees itself.

**Boss triggers:**
- `BOSS_KILL_THRESHOLD = 10`. Four independent family kill counters (`_zone_c_slime_killed`, `_zone_a_orc_killed`, `_zone_a_plant_killed`, `_zone_b_vampire_killed`) and four boss-spawned flags.
- When a family's count reaches the threshold, the matching boss spawns once at world center; `boss_health_bar.tscn` is instantiated and `init(boss)` called.
- Export vars: `slime1/2/3_scene`, `slime3_boss_scene`, `orc1/2/3_scene`, `orc3_boss_scene`, `plant1/2/3_scene`, `plant3_boss_scene`, `vampire1/2/3_scene`, `vampire3_boss_scene` — all must be assigned in the Godot editor inspector.

**Testing mode:**
- When `SceneManager.testing_mode` is true, all bounty timers stop and each zone is filled to 10 weighted-random mobs. Testing mobs do not affect bounty or boss counters. SELECT opens the teleport menu to jump between zones.

**TownEntrance** (Area2D at south edge): triggers `SceneManager.go_to_town()` when player enters.

---

### 11. Town Scene — `world/town.gd`

4800×2700 px playable area ("Thornwall").

**Camera:** Zoomed 3.5× in `_ready()`.

- On load: reads `world_registry.json`, assigns `npc_id` / `npc_name` to each NPC node by role, then calls `reload_all_dialogue()`.
- `FieldExit` Area2D triggers `SceneManager.go_to_field()`.
- `Ctrl+R`: triggers `SceneManager.trigger_chronicle()`.

---

### 12. MobStats — `mob/mob_stats.gd`

All mob balance constants in one file. Edit here to tune any enemy without touching logic scripts. Grouped by family (Slimes → Orcs → Plants → Vampires), then Bosses. Each mob's section covers:

- `MAX_HEALTH`, `DAMAGE`, `KNOCKBACK`, `AGGRO_RADIUS`, `HITBOX_RADIUS`
- Speed constants (SPEED_MIN/MAX for slimes; WANDER_SPEED/AGGRO_SPEED for plants; WANDER_SPEED/CHARGE_SPEED for orcs; ORBIT_SPEED/DASH_SPEED for vampires)
- AI behaviour radii and timers (PACK_TRIGGER_RADIUS, CHARGE_TRIGGER_RADIUS, ORBIT_RADIUS, STRIKE_RADIUS, DASH_DURATION, RECOVER_DURATION, etc.)
- Boss section adds: AOE/beam attack constants, ATTACK_COOLDOWN, TELEGRAPH_DURATION, GOOP_DROP

Previously the hitbox constants lived on `mob_base.gd`; they now live here. All mob scripts reference `MobStats.X` — their local behavior constants are re-exported from this file via `const FOO = MobStats.X`.

---

### 13. Mob Base — `mob/mob_base.gd`

Base class (extends `RigidBody2D`) for all enemy types.

**Enums:**
- `Personality`: `WANDER`, `WEAK_AGGRESSIVE`, `PACK_MENTALITY`, `BOSS`
- `AIState`: `WANDER_STATE`, `CHASE_STATE`, `FLEE_STATE`

**Exports:** `max_health`, `personality`, `aggro_radius`, `pack_radius`, `pack_threshold`

**Key methods:**
- `take_damage(amount, knockback_vec)`: decrement health, apply impulse, flash red for 0.15 s, call `_on_died()` if health ≤ 0
- `_on_died()`: emit `died(self)`, call `queue_free()`
- `_direction_to_player_with_noise(speed)`: normalized direction to player with ±15° sine noise × speed
- `_nav_move(speed)`: like `_direction_to_player_with_noise` but paths via `NavigationAgent2D` when a baked `NavigationRegion2D` is present; falls back to direct movement if no nav map exists
- `_distance_to_player()`: returns INF if no player ref found

**Signal:** `died(mob: Node)` — connected by `field.gd` at spawn time.

`_ready()` adds mob to group `"ground_mobs"` and finds the player reference.

---

### 14. Slime1 — `mob/slime1.gd`

Extends `mob_base`. `max_health=3`, `personality=PACK_MENTALITY`, `aggro_radius=300`, `damage=1`, `knockback_force=200`. Speed 40–70 px/s. Zone: zone_c.

- Wander: random direction, 1–3 s move / 1–4 s pause cycle.
- AI (pack link system): flees alone; links pack when ≥2 nearby slime1 within `PACK_TRIGGER_RADIUS=200px`. Aggro cascades to all linked slime1s every `LINK_SCAN_INTERVAL=0.5s`.
- **Leash:** de-aggros and returns to zone center if it wanders outside its home zone.
- Sprites: `.aseprite` per animation/direction from `assets/mobs/Slime1/`.
- Boundary clamping in `_integrate_forces()`.

---

### 15. Slime2 — `mob/slime2.gd`

Extends `mob_base`. `max_health=6`, `personality=PACK_MENTALITY`, `aggro_radius=200`, `damage=2`, `knockback_force=350`. Speed 50–100 px/s. Zone: zone_c.

- AI: **Passive until attacked.** When hit, permanently aggroes and calls `_alert_nearby_pack()` (alerts all slime2 within `ALERT_RADIUS=200px`). Once aggroed, chases player indefinitely.
- Sprites: `.aseprite` per animation/direction from `assets/mobs/Slime2/`.
- Boundary clamping in `_integrate_forces()`.

---

### 16. Slime3 — `mob/slime3.gd`

Extends `mob_base`. `max_health=8`, `personality=WEAK_AGGRESSIVE`, `aggro_radius=250`, `damage=2`, `knockback_force=250`. Speed 60–110 px/s. Zone: zone_c.

- Chases player on sight; returns to wander when player leaves aggro range.
- Sprites: `.aseprite` per animation/direction from `assets/mobs/Slime3/`.
- Boundary clamping in `_integrate_forces()`.

---

### 17. Slime3 Boss — `mob/slime3_boss.gd`

Extends `mob_base`. `max_health=30`, `personality=BOSS`, `damage=5`, `knockback_force=600`. Drops 20 Slime Goop. Spawns after 10 **combined** slime kills.

- Always chases; AOE attack with 1.5 s telegraph. `AOE_RADIUS=150`, `AOE_DAMAGE=7`, `AOE_KNOCKBACK=700`, `ATTACK_COOLDOWN=5s`.
- Sprites: from `assets/mobs/Slime3/` (includes Attack animation).

---

### 18. Orc1/2/3 — `mob/orc1.gd`, `mob/orc2.gd`, `mob/orc3.gd`

Charger AI. Zone: zone_a. HP 8/14/22, dmg 2/3/4, knockback 250/350/450, charge speed 280/320/360.
`_is_attacking=true` during CHARGE phase only. See `docs/game_mechanics.md` for AI detail.

---

### 19. Orc3 Boss — `mob/orc3_boss.gd`

HP=60, dmg=6, kb=600. Drops 15 Goop. Spawns after 10 combined orc kills.
Telegraphed charge (1.5 s orange indicator via `_draw()`), then 500 px/s charge for 1.0 s.

---

### 20. Plant1/2/3 — `mob/plant1.gd`, `mob/plant2.gd`, `mob/plant3.gd`

Creeper AI. Zone: zone_a. HP 10/18/28, dmg 2/3/5, knockback 200/300/400.
`_is_attacking=true` while within `STRIKE_RADIUS=90 px` and playing walk_attack. See `docs/game_mechanics.md`.

---

### 21. Plant3 Boss — `mob/plant3_boss.gd`

HP=50, dmg=7, kb=500. Drops 15 Goop. Spawns after 10 combined plant kills.
Starburst AOE: 5 beams drawn via `_draw()`, 2.0 s telegraph, angular hit check (±0.35 rad per beam, reach=400 px).

---

### 22. Vampire1/2/3 — `mob/vampire1.gd`, `mob/vampire2.gd`, `mob/vampire3.gd`

Stalker AI. Zone: zone_b. HP 6/10/16, dmg 1/2/3, knockback 200/300/400.
Orbits at 200 px, dashes at player on timer (`_is_attacking=true` during dash). See `docs/game_mechanics.md`.

---

### 23. Vampire3 Boss — `mob/vampire3_boss.gd`

HP=40, dmg=5, kb=400. Drops 15 Goop. Spawns after 20 combined vampire kills.
Faster orbit/dash; life drain: heals 4 HP when dash connects.

---

### 24. Weapon HUD — `ui/weapon_hud.gd`

Top-center CanvasLayer (layer 6). Two slots: sword, axe. Built entirely in code.

- **Active**: gold border (3 px) + gold label text.
- **Owned inactive**: normal border + gold text.
- **Locked** (not owned): dim border + grey text + ` [lock]` suffix.
- Connects to `SceneManager.inventory_updated` and player's `weapon_changed` signal (deferred lookup via group `"player"`).

---

### 25. Minimap — `ui/minimap.gd`

Bottom-right CanvasLayer (layer 4), **field scene only**. Instantiated by `field.gd._ready()`.

- 375 px wide; height computed to match the 16:9 world aspect ratio (~211 px). 16 px margin from the screen edge.
- Terrain from `TileMapLayer` nodes is pre-baked into an `ImageTexture` once at init. Bounty zones rendered as semi-transparent coloured overlays.
- **North is always up**; the map does not rotate.
- **Player** drawn as a filled gold circle (5.5 px radius) with a directional triangle pointing toward `player.facing`.
- **Enemies** drawn as 3.5 px red dots (group `"ground_mobs"`); bosses drawn in orange.
- Redraws every frame via `_process → queue_redraw`.
- All drawing is done via the `draw` signal on an inner Control node.

### 26. Boss Health Bar — `ui/boss_health_bar.gd`

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
| `select` | Tab | Back button (Select) |

`select` is used only in the field scene when `testing_mode` is ON — it opens the teleport menu.

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
- **Bounty zones:** Zones `zone_a/b/c` map 1-to-1 to `TerrainNW/NE/SE` ColorRect nodes in `field.tscn` (visually NE/SE/SW — node names are misnamed). Mob meta tag `bounty_zone` links kills to the correct bounty entry.
- **Guild commander patch:** `npc_base.gd:_patch_guild_commander_root()` dynamically replaces the first response option with "I have completed a bounty" if any bounty has `status == "complete"`, enabling the turn-in flow without changing the LLM dialogue.
- **Scripts currency:** Scripts are the player's primary currency. Earned by turning in bounties. Displayed top-left. Spent at the blacksmith to buy the axe (50 Scripts) and upgrade weapons.

---

*Update this file whenever a component, scene, script, or feature is added, removed, or significantly refactored.*
