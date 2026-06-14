# BARD — Game Systems Reference

**Live document.** Update this file whenever a system is added, changed, debugged, or extended.  
This is the authoritative map of how each feature works end-to-end, so implementation details never need to be reverse-engineered from scratch.

---

## Table of Contents

1. [Scene Transitions](#1-scene-transitions)
2. [Save / Load](#2-save--load)
3. [End of Day](#3-end-of-day)
4. [Day Summary Screen](#4-day-summary-screen)
5. [LLM Pipeline Overview](#5-llm-pipeline-overview)
6. [World Generation (One-Time Setup)](#6-world-generation-one-time-setup)
7. [End-of-Day LLM Pipeline](#7-end-of-day-llm-pipeline)
8. [Chronicle Pipeline](#8-chronicle-pipeline)
9. [NPC Dialogue System](#9-npc-dialogue-system)
10. [Wandering NPCs and Ambient Exchanges](#10-wandering-npcs-and-ambient-exchanges)
11. [Dialogue Box](#11-dialogue-box)
12. [Bounty Board](#12-bounty-board)
13. [Bounty Tracker HUD](#13-bounty-tracker-hud)
14. [Bounty Turn-In](#14-bounty-turn-in)
15. [Weapon Purchasing and Upgrading](#15-weapon-purchasing-and-upgrading)
16. [Mob Spawning in the Field](#16-mob-spawning-in-the-field)
17. [Boss Triggers](#17-boss-triggers)
18. [Game State and Persistence](#18-game-state-and-persistence)
19. [Pipeline Progress Bar](#19-pipeline-progress-bar)

---

## 1. Scene Transitions

**Owner:** `autoload/scene_manager.gd` — `_transition_to(scene_path)` / `go_to_field()` / `go_to_town()`

### How it works

All scene changes route through `_transition_to(scene_path)`. Nothing calls `get_tree().change_scene_to_file()` directly.

```
SceneManager.go_to_field() / go_to_town()
  → _transition_to(scene_path)
      • guard: if _transitioning → return (prevents double-trigger)
      • read area display name from world_registry.json (town) or hardcoded (field)
      • instantiate loading_screen.tscn
      • await ls.run_enter(area_name)      ← fade-in animation with area name
      • get_tree().change_scene_to_file()  ← actual scene swap
      • await ls.run_exit()               ← fade-out
      • ls.queue_free()
      • _transitioning = false
```

### Scene paths
| Constant | Path |
|----------|------|
| `FIELD_SCENE` | `res://world/field.tscn` |
| `TOWN_SCENE` | `res://world/town.tscn` |

### Town entrance trigger (field → town)

`field.gd` has a `TownEntrance` Area2D at the south edge of the map. When the player's Area2D enters it, `SceneManager.go_to_town()` is called. Detection uses `_is_player(area)` which checks the area or its parent for the `"player"` group.

### Field exit trigger (town → field)

`town.gd` has a `FieldExit` Area2D. Entering it calls `SceneManager.go_to_field()`.

### What to keep in mind
- Loading screen is instantiated fresh on every transition. It is not a persistent node.
- `_transitioning` flag prevents re-entry; do not call `go_to_field()` / `go_to_town()` inside a `body_entered` or similar rapid-fire signal without checking this.
- The end-of-day pipeline calls `go_to_town()` automatically once the pipeline completes.

---

## 2. Save / Load

**Owner:** `autoload/scene_manager.gd` — `save_game(slot)` / `load_game(slot)` / `has_save(slot)`

### File path

`save_{slot}.json` at the project root (e.g., `save_0.json`, `save_1.json`).

### What is saved

```
meta.schema_version, meta.day, meta.scene_path
player_name, scripts, slime_goop, owned_weapons, weapon_upgrades, player_health
world_state.monsters_killed_today, world_state.monsters_killed_history
available_bounties, active_bounties
flags
```

`npc_facts` is NOT stored in the save file — it lives only in `game_state.json` (the pipeline's source of truth). Save files capture Godot-owned state; the pipeline captures memory.

### Save format (schema 1.0)
```json
{
  "meta": { "schema_version": "1.0", "day": 3, "scene_path": "res://world/town.tscn" },
  "player_name": "Aerin",
  "scripts": 75,
  "slime_goop": 2,
  "owned_weapons": ["sword", "axe"],
  "weapon_upgrades": { "sword": 1 },
  "player_health": 80,
  "world_state": { "monsters_killed_today": {}, "monsters_killed_history": [{...}] },
  "available_bounties": [...],
  "active_bounties": [...],
  "flags": { "met_yara_varen": true, ... }
}
```

### Load sequence

1. Parse `save_{slot}.json`
2. Overwrite all SceneManager fields from the file
3. Emit `bounties_updated`, `scripts_updated`, `player_health_changed`, `inventory_updated`, `day_updated` to sync all HUD elements
4. Call `_transition_to(scene_path)` — player drops back into whatever scene they saved in

### What to keep in mind
- `has_save(slot)` is a simple file-existence check — always call it before `load_game()`.
- Slot numbers are arbitrary integers; the game currently uses a single implicit slot.
- `weapon_upgrades` is a `Dictionary` keyed by weapon ID. Absence of a key means tier 0 (unupgraded).

---

## 3. End of Day

**Owner:** `autoload/scene_manager.gd` — `end_day()`

Triggered by the innkeeper "Good night" dialogue action (`action: "end_day"` in the dialogue JSON, processed by `ui/dialog_box.gd`).

### Sequence

```
end_day()
  1. Snapshot _scripts_earned_today and _bounties_turned_in_today (for summary)
  2. Reset those accumulators to zero / empty
  3. monsters_killed_history.append(monsters_killed_today.duplicate())
  4. monsters_killed_today.clear()
  5. day += 1  →  day_updated.emit()
  6. Filter active_bounties: keep only "turned_in" entries (un-turned bounties expire)
  7. refresh_daily_bounties()   ← repopulate available_bounties from bounty_pool.json
  8. _write_game_state()        ← write game_state.json BEFORE launching pipeline
  9. _show_day_summary(earned, turned)   ← blocks on keypress; then launches pipeline
```

### Key rule
`game_state.json` is written **before** the pipeline starts. The pipeline always reads the completed day's data, not work-in-progress.

### What happens to bounties on day end
- `"turned_in"` bounties survive into the next day (preserved in active_bounties).
- `"active"` and `"complete"` bounties that were not turned in are dropped.
- `available_bounties` is repopulated from `data/bounty_pool.json`, excluding any `id` still present in `active_bounties`.

---

## 4. Day Summary Screen

**Owner:** `autoload/scene_manager.gd` — `_show_day_summary(earned, turned)`

Built entirely in code. A full-screen dark overlay (CanvasLayer, layer 150) showing:
- Heading: `── Day N Summary ──`
- Contracts turned in today (flavor text + Scripts earned per bounty)
- Total scripts earned today + running total
- `[ press any key ]` prompt

Blocks via `await _wait_for_keypress()` — polls `Input.is_anything_pressed()` each process frame. After keypress, the layer is freed and `_start_pipeline("eod")` is called.

---

## 5. LLM Pipeline Overview

All LLM work happens in Python (`pipeline/`) as a subprocess launched via `OS.create_process(PYTHON_EXE, [script_path])`. Godot never blocks; it polls for sentinel flag files every 3 seconds.

### Communication model

```
Godot                          Python pipeline
  │                                  │
  ├── writes game_state.json         │
  ├── OS.create_process(python) ────►│
  ├── shows overlay                  │
  │                                  ├── does LLM work
  │   (polls every 3 s)              ├── writes pipeline_progress.json
  │◄──────────────────────────────── │     (Godot reads this for progress bar)
  │                                  ├── writes dialogue JSON files
  │                                  └── writes pipeline_ready.flag
  │
  ├── detects flag → _on_pipeline_result("ready", "")
  ├── dismisses overlay
  ├── calls _reload_all_dialogue()
  └── go_to_town()
```

### Pipeline modes

| Mode | Script | Flag prefix | Trigger |
|------|--------|-------------|---------|
| `eod` | `pipeline/end_of_day.py` | `pipeline_` | `end_day()` via innkeeper |
| `chronicle` | `pipeline/chronicle.py` | `pipeline_chronicle_` | `Ctrl+R` in town |

### Flag files (project root)

| File | Meaning |
|------|---------|
| `pipeline_ready.flag` | Success — Godot may proceed |
| `pipeline_failed.flag` | Partial success — fallback dialogue used |
| `pipeline_crashed.flag` | Unhandled exception — crash overlay shown |
| `pipeline_chronicle_ready.flag` | Chronicle success |
| `pipeline_chronicle_failed.flag` | Chronicle partial |
| `pipeline_chronicle_crashed.flag` | Chronicle crash |

### Timeout
180 seconds (`PIPELINE_TIMEOUT`). If the pipeline hasn't written any flag within that time, Godot treats it as a crash and shows an error overlay.

### LLM backend
- **Runtime:** Ollama, local GPU
- **Model:** Gemma 4 E4B (configurable via env var in `config.py`)
- **Endpoint:** `http://localhost:11434/api/generate`
- **Retry:** 3 attempts, 2 s delay between (`ollama_client.py`)
- **Auto-start:** pipeline attempts `try_start_ollama()` if Ollama is not reachable

---

## 6. World Generation (One-Time Setup)

**Script:** `pipeline/world_gen.py` — run manually once before the first play session.

### Steps
1. Read or prompt for the player's name (also supports LLM-generated names)
2. Generate world lore via LLM (or fall back to `pipeline/fallbacks/world_lore.json`)
3. For each archetype role (`innkeeper`, `blacksmith`, `guild_commander`):
   - Read the base archetype from `archetypes/{role}.json`
   - Generate 3 named variants (A, B, C) via LLM using NPC generation rules from `archetypes/npc_generation_rules.json`
   - Write each variant to `archetypes/generated/{role}_{A|B|C}.json`
4. Randomly assign one variant per role per town, write `world_registry.json`
5. Write initial `game_state.json` (day 1, no kills, no flags)
6. Write `world_lore.json`
7. Run `end_of_day.py` as a subprocess to generate Day 1 dialogue before the game starts

### Output files

| File | Contents |
|------|----------|
| `world_lore.json` | Generated lore facts for world and per-town |
| `world_registry.json` | NPC-to-town assignments, variant IDs, display names |
| `archetypes/generated/*.json` | LLM-created NPC variant personalities |
| `game_state.json` | Initial game state (day 1) |

### What to keep in mind
- Running `world_gen.py` again overwrites all of the above and resets the game.
- Variant assignment is random — which variant of each role appears in Thornwall changes each new game.
- Player name is written into `game_state.json` and persists across days.

---

## 7. End-of-Day LLM Pipeline

**Script:** `pipeline/end_of_day.py`

### Per-NPC loop

For each named NPC in `world_registry.json` → `towns.thornwall.npcs`:

```
1. write_progress(idx, total, npc_name)       ← updates progress bar in Godot
2. load_variant(variant_id)                   ← from archetypes/generated/
3. build_prompt(variant, world_lore, game_state, npc_id, town_id, rumors)
      • system prompt: NPC identity + role + town lore seed
      • user prompt:   day number, kill report, bounty status, met-flags,
                       NPC recollection facts, circulating rumors,
                       role-specific context (guild records / inn context)
4. call_ollama_json(prompt, system)           ← HTTP POST to Ollama
5. validate_dialogue(result)                  ← schema check
   if invalid:
     repair_dialogue(broken_output, error)    ← second LLM call to fix JSON
     re-validate
   if still invalid or no result:
     load_previous_dialogue(npc_id, day)      ← walk back from day-1
6. post_process_dialogue()                    ← add npc_id, npc_name, day, key fields,
                                                  inject action:"end_day" on sleep responses
7. write dialogue/{npc_id}_day{N}.json
8. generate_recollection(variant, game_state, npc_id)
      ← second LLM call: one subjective sentence from NPC's perspective
9. update_npc_facts(game_state, npc_id, new_fact, day)
```

Each NPC has a **90-second timeout** (`NPC_TIMEOUT_SECONDS`). Timeout → use previous dialogue, mark `had_failures = True`.

### Dialogue JSON schema (generated)
```json
{
  "npc_id": "yara_varen",
  "npc_name": "Yara Varen",
  "day": 3,
  "nodes": {
    "greeting": {
      "text": "NPC opening line.",
      "responses": [{"text": "Player reply.", "next": "some_node", "key": 1}]
    },
    "some_node": { "text": "...", "responses": [...] },
    "farewell": {
      "text": "Closing line.",
      "responses": [{"text": "Goodbye.", "next": null, "key": 1}]
    }
  }
}
```

### Validation rules enforced
- `greeting` and `farewell` nodes are required
- All `next` values must be null or point to an existing node
- `farewell` responses must all have `next: null`
- Cycle detection: every node must have a path to farewell or null

### Fallback chain
```
LLM call → retry (×3) → validate → repair call → re-validate
  → previous day's file (walking back to day 1)
  → log error, skip NPC
```

### After all NPCs complete

1. Update `game_state.json` `npc_facts` section (pipeline only touches this field)
2. `generate_ambient_exchanges()` — generate a pool of 10 short two-line ambient exchanges for wandering villagers, written to `dialogue/villager_ambient_day{N}.json`
3. Write `pipeline_ready.flag` or `pipeline_failed.flag`

---

## 8. Chronicle Pipeline

**Script:** `pipeline/chronicle.py`  
**Trigger:** `Ctrl+R` in town → `SceneManager.trigger_chronicle()`

The chronicle does **not** advance the day. It generates a narrative record and gossip without modifying kill counts or bounties.

### Steps

1. Load `game_state.json`, `world_lore.json`, most recent existing chronicle (narrative field only for continuity)
2. Build NL summary of the week from `monsters_killed_history`
3. LLM call → generates `narrative`, `key_events[]`, `player_deeds[]`
4. Write `chronicles/week_N.json`
5. For each player deed, generate one rumor:
   - 75% chance: rumor names the player directly
   - 25% chance: traceable but anonymous
6. Prune `rumors.json` to 10 entries maximum (oldest first)
7. Write `rumors.json`
8. Write `pipeline_chronicle_ready.flag`

### What rumors do
Rumors persist in `rumors.json` and are injected into future end-of-day prompts via `build_rumor_context()` in `nl_descriptors.py`. They give NPCs awareness of the player's deeds without direct observation.

---

## 9. NPC Dialogue System

**Owner:** `npc/npc_base.gd`

### How dialogue is loaded

Each named NPC has a `dialogue_file` export set by `town.gd` at load time to `res://dialogue/{npc_id}_day{N}.json`. `_load_dialogue()` reads this file and merges it with hardcoded role menus:

```
_load_dialogue()
  → read dialogue_file → parse JSON → get "nodes" dict
  → _build_merged_dialogue(generated)
      if npc_role has a ROLE_ROOT_NODES entry:
        start with hardcoded role root (innkeeper / blacksmith / guild_commander)
        if generated is empty: remove "Talk" / "greeting" response from root
        if generated exists: append generated nodes (hardcoded keys win on collision)
      if no role (wanderers): return generated as-is
  → store in _dialogue_nodes
```

### Hardcoded role root nodes

Every named NPC always has these regardless of LLM output:

| Role | Root options |
|------|-------------|
| `innkeeper` | Sleep, Browse shop, Talk, Goodbye |
| `blacksmith` | Browse wares, Upgrade weapons (dynamic), Talk, Goodbye |
| `guild_commander` | Bounty board / Turn in (dynamic), Talk, Goodbye |

The LLM only generates the `greeting` node and conversational branches. The `Talk` option in the root links to `greeting`.

### Dynamic patches applied at open time

**Guild commander** (`_patch_guild_commander_root()`): if any active bounty has `status == "complete"`, the first root response is replaced with "I have completed a bounty" → `turnin_confirm` → `open_turn_in` action.

**Blacksmith** (`_patch_blacksmith_root()`): `upgrade_menu` responses are filtered based on `SceneManager.owned_weapons`. "Buy Axe" hidden if already owned. "Upgrade Sword/Axe" shown only for owned weapons.

### Proximity detection

The `DetectionArea` (Area2D, layer=0, mask=2) scans for the player area (player is on layer 2). On enter: show name label + Talk prompt, set `met_{npc_id}` flag. On exit: hide prompt, close dialogue if open.

Press `interact` (E / A) to open dialogue — it never auto-opens.

### Dialogue reload after pipeline

`SceneManager._reload_all_dialogue()` is called after every pipeline completion. It calls `reload_dialogue()` on every node in group `"npc"`. This updates `dialogue_file` to the new day's path and re-runs `_load_dialogue()` without re-instantiating the NPC.

---

## 10. Wandering NPCs and Ambient Exchanges

**Owner:** `npc/npc_base.gd` — controlled by `is_wanderer = true`

### Wandering behaviour

- Speed: `WANDER_SPEED = 38.0 px/s`
- Direction: random, picked every 2.5–6 s via `_pick_wander_direction()` (30% chance to idle instead)
- Bounds: clamped to `_world_bounds` (set by town scene). On hitting bounds, new direction is picked.
- No dialogue — wanderers carry no `dialogue_file` and return empty from `_build_merged_dialogue`.
- Added to group `"wanderer"`.

### Ambient chat between wanderers

Wandering NPCs can trigger brief two-line exchanges with nearby wanderers:

- `CHAT_RADIUS = 60.0 px` — scan radius for another wanderer
- `CHAT_COOLDOWN = 30.0 s` — minimum time between chats for this NPC
- `CHAT_DURATION = 4.0 s` — how long a chat lasts
- When within range and cooldown expired, `_check_nearby_chat()` fires, pauses both NPCs, plays a speech bubble or exchange (implementation in npc_base).
- Chat lines are drawn from `dialogue/villager_ambient_day{N}.json`, generated by the end-of-day pipeline.

### Physics

Only **named (non-wandering) NPCs** get a `StaticBody2D` child (layer 8, mask 0, radius 12 px) added in `_add_physics_body()`. They are also added to group `"npc_blocker"` so player script-level blocking applies. Wandering NPCs have no physics body — the player passes through them. See `docs/game_mechanics.md` for the full collision explanation.

---

## 11. Dialogue Box

**Owner:** `ui/dialog_box.gd` + `ui/dialog_box.tscn`  
**Layer:** 10

A fixed-size (1000×292 px) bottom-center overlay. Added to group `"dialogue_box"` so NPCs can find it with `get_first_node_in_group()`.

### Open / close

`open(nodes, start_node, speaker_name)` — freezes player (`set_gameplay_active(false)`).  
`close()` — restores player. Also emits signal `closed`.

Auto-closes when the player walks out of the NPC's detection range.

### Interaction

- Typewriter effect: 0.028 s/character via internal timer.
- Any key / button press skips to full text.
- D-pad ↑↓ / arrow keys navigate response options. Selected response shown in gold with 2 px underline.
- `interact` (E / A) confirms the selected response.

### Built-in dialogue actions

Processed by `dialog_box.gd` when a response with an `action` key is confirmed:

| Action | Effect |
|--------|--------|
| `end_day` | Close box → `SceneManager.end_day()` |
| `go_to_field` | `SceneManager.go_to_field()` |
| `go_to_town` | `SceneManager.go_to_town()` |
| `open_turn_in` | Instantiate `bounty_turnin.tscn` |
| `buy_axe` | Deduct 50 Scripts → `SceneManager.buy_weapon("axe", 50)` |
| `upgrade_sword` | Deduct 100 Scripts + 5 Goop → `SceneManager.upgrade_weapon("sword", 100, 5)` |
| `upgrade_axe` | Deduct 150 Scripts + 10 Goop → `SceneManager.upgrade_weapon("axe", 150, 10)` |

Insufficient funds: a transient `_insufficient_funds` node is injected into `_dialogue_nodes` at `open()` time and shown instead of the confirmation node.

---

## 11a. Pause Menu — Bounty Management

**Owner:** `ui/pause_bounty_screen.gd`  
**Trigger:** "Bounties" option in the pause menu (index 3)

Opened as a `Control` child of the pause menu's CanvasLayer. Uses the same dark-parchment palette and split layout (scrollable list left, detail pane right) as the bounty board.

### What it shows
- All active bounties with `status != "turned_in"`: name, zone, kill progress.
- Detail pane: monster image, flavor text, current progress, reward, and a "[A] Drop this contract" prompt.

### Navigation
- ↑↓ (`menu_up` / `menu_down`): cycle through active bounties.
- `interact` (A / E): open drop-confirm dialog for the selected bounty.
- `menu_cancel` or `pause` (B / Esc): close and return to pause menu.

### Drop-confirm overlay
A small centered panel warns:  
*"Dropping this contract will reset all kill progress and return it to the bounty board."*  
Options: **Yes, drop it** / **No, keep it**. Navigated with ↑↓; confirmed with `interact`.

### Drop flow
```
Player confirms drop
  → SceneManager.drop_bounty(bounty_id)
      • remove from active_bounties
      • re-read bounty_pool.json → append fresh copy to available_bounties
      • bounties_updated.emit()
  → screen refreshes automatically
```

Kill progress is always lost on drop — the bounty returns to the board in its original unstarted state.

---

## 12. Bounty Board

**Owner:** `ui/bounty_board.gd` + `world/bounty_board_object.gd`

### World object

`BountyBoardObject` (Node2D, `world/bounty_board_object.gd`): proximity detect (radius 140 px); shows `[A] Bounty Board` prompt. Press `interact` → instantiate and open `bounty_board.tscn`. Freezes player while open.

### Board UI (full-screen CanvasLayer, layer 20)

- **AVAILABLE section:** lists available bounties from `SceneManager.available_bounties`. D-pad ↑↓ navigates; selected row in gold. Press `interact` → `SceneManager.accept_bounty(bounty_id)`.
- **ACTIVE section:** display-only. Shows status badge: "In Progress" or "Complete".
- One active bounty per zone at a time — `accept_bounty()` enforces this.
- Close: `menu_cancel` (Esc / B).
- Rebuilds entirely on `SceneManager.bounties_updated` signal.

### Bounty data source

`data/bounty_pool.json` — static definitions (9 entries: 3 zones × 3 tiers). Not modified at runtime.

### Reward tiers

| ID suffix | Scripts reward |
|-----------|---------------|
| `_small` | 10 |
| `_medium` | 25 |
| `_large` | 50 |

---

## 13. Bounty Tracker HUD

**Owner:** `ui/bounty_tracker.gd`  
**Layer:** 15 (top-right)

Passive overlay. Shows active/in-progress bounties with flavor text and `killed / quantity` counter. Hidden when no active bounties. Rebuilds instantly on `SceneManager.bounties_updated`.

---

## 14. Bounty Turn-In

**Owner:** `ui/bounty_turnin.gd`  
**Trigger:** dialogue action `"open_turn_in"` from guild commander

Opened as a new CanvasLayer overlay. Lists only completed (`status == "complete"`) bounties. D-pad ↑↓ navigates; press `interact` → `SceneManager.turn_in_bounty(bounty_id)` → awards Scripts → marks `"turned_in"`. Auto-closes when all completed bounties are turned in. `menu_cancel` closes early.

### Turn-in flow
```
Player selects bounty → turn_in_bounty(id)
  → bounty["status"] = "turned_in"
  → _bounties_turned_in_today.append(bounty)     ← for day summary
  → earn_scripts(scripts_for_bounty(bounty))
  → bounties_updated.emit()
```

---

## 15. Weapon Purchasing and Upgrading

**Owner:** `autoload/scene_manager.gd` + `npc/npc_base.gd` + `ui/dialog_box.gd`

### Purchase (Buy Axe)

Triggered by dialogue action `"buy_axe"`. `dialog_box.gd` calls `SceneManager.buy_weapon("axe", 50)`:
- Guard: if `scripts < 50` or `"axe" in owned_weapons` → no-op
- `scripts -= 50`, `owned_weapons.append("axe")`
- Emit `scripts_updated`, `inventory_updated`
- `WeaponHUD` and `player.gd` react to `inventory_updated`

### Upgrade

Triggered by `"upgrade_sword"` or `"upgrade_axe"` actions. `SceneManager.upgrade_weapon(id, cost_scripts, cost_goop)`:
- Guard: if `scripts < cost_scripts` or `slime_goop < cost_goop` → no-op
- Deduct both currencies
- `weapon_upgrades[id] = weapon_upgrades.get(id, 0) + 1`
- Emit `scripts_updated`, `inventory_updated`

### Current upgrade costs

| Action | Scripts | Slime Goop |
|--------|---------|-----------|
| `upgrade_sword` | 100 | 5 |
| `upgrade_axe` | 150 | 10 |

### Dynamic blacksmith menu

`npc_base._patch_blacksmith_root()` modifies the `upgrade_menu` node in `_dialogue_nodes` at `open()` time based on current `SceneManager.owned_weapons`. This ensures "Buy Axe" only appears when the player doesn't own it, and upgrade options only appear for owned weapons. No dialogue file rewrite needed.

### Weapon data

All weapon stats live in `Player/weapons/`:

| File | ID | DAMAGE | KNOCKBACK | Notes |
|------|----|--------|-----------|-------|
| `sword_data.gd` | `"sword"` | 1 | 200.0 | Default weapon |
| `axe_data.gd` | `"axe"` | 2 | 400.0 | Purchasable from blacksmith |

Upgrade tier is tracked in `SceneManager.weapon_upgrades["sword"]` / `["axe"]` but is not yet applied to stats — stat scaling is a future phase.

---

## 16. Mob Spawning in the Field

**Owner:** `world/field.gd`

### Bounty zones

Three zones map to `ColorRect` terrain nodes in `field.tscn`:

| Zone key | Terrain node | Location |
|----------|-------------|---------|
| `zone_a` | `TerrainNW` | NW corner |
| `zone_b` | `TerrainNE` | NE corner |
| `zone_c` | `TerrainSE` | SE corner |

### Spawn logic

On `_ready()`, `_start_bounty_spawning()` iterates all `SceneManager.active_bounties`. For each bounty:
- Create a repeating `Timer` (wait 3.5 s) stored in `_bounty_timers[zone]`
- One mob spawns immediately via `_spawn_bounty_mob(monster_type, zone)`
- Timer fires every 3.5 s, spawning another until `MAX_MOBS_PER_ZONE = 5` reached

`_count_zone_mobs(zone)` counts alive mobs in `MobContainer` that have meta `bounty_zone == zone`.

On `SceneManager.bounties_updated`, `_start_bounty_spawning()` is called again to pick up newly accepted bounties.

### Mob scene assignment

Scenes are `@export` vars assigned in the Godot editor inspector on `field.tscn`:

| Export var | Scene |
|-----------|-------|
| `slime1_scene` | `mob/slime1.tscn` |
| `slime2_scene` | `mob/slime2.tscn` |
| `slime3_scene` | `mob/slime3.tscn` |
| `slime1_boss_scene` | `mob/slime1_boss.tscn` |
| `slime2_boss_scene` | `mob/slime2_boss.tscn` |
| `slime3_boss_scene` | `mob/slime3_boss.tscn` |

### On kill

`_on_mob_died(mob_body)` (connected at spawn via `mob.died.connect(...)`):
1. `SceneManager.record_kill(monster_type)` — increments `monsters_killed_today`
2. If mob has `bounty_zone` meta: `SceneManager.record_bounty_kill(monster_type, zone)` — increments bounty kill counter, marks complete when quota met
3. Increments the per-type local counter (`_slime1_killed` etc.)
4. `_check_boss_triggers()`

Mob meta tags set at spawn time:
- `set_meta("bounty_zone", zone)` — links kill to the correct bounty
- `set_meta("monster_type", type_string)` — set by the mob script itself in `_ready()`

---

## 17. Boss Triggers

**Owner:** `world/field.gd`

Each slime type has an independent boss trigger:

- `BOSS_KILL_THRESHOLD = 20` — kills of that type required
- Per-type kill counters: `_slime1_killed`, `_slime2_killed`, `_slime3_killed`
- Per-type spawn flags: `_slime1_boss_spawned` etc. (prevent double-spawn)

On threshold reached:
1. `call_deferred("_spawn_boss", type)` — deferred to avoid spawning mid-physics step
2. Boss instantiated at `world_size * 0.5` (map center)
3. `boss_health_bar.tscn` instantiated, `init(boss)` called — connects to `boss.died` signal, shows top-center HP bar
4. Boss drops 5 Slime Goop on death (handled in the boss mob script)

---

## 18. Game State and Persistence

Two separate JSON files serve different purposes:

### `game_state.json` (pipeline source of truth)
Written by Godot via `_write_game_state()` before each pipeline run. Read exclusively by Python scripts. Contains everything in the save file plus `npc_facts`. The pipeline appends to `npc_facts` and writes it back — it does not touch any other field.

### `save_{slot}.json` (player save)
Written by `SceneManager.save_game(slot)`. Read by `SceneManager.load_game(slot)`. Does not contain `npc_facts` — those are pipeline-owned.

### `world_registry.json`
Written once by `world_gen.py`. Read by `town.gd` to assign NPC names and roles, and by `SceneManager._get_area_name()` to display the town's display name on the loading screen.

### `world_lore.json`
Written once by `world_gen.py`. Injected into every LLM prompt as world and town lore facts.

### `pipeline_progress.json`
Written by `end_of_day.py` during the run. Polled every 3 s by Godot. Format:
```json
{ "total": 3, "completed": 1, "current_npc": "Yara Varen" }
```

---

## 19. Pipeline Progress Bar

**Owner:** `autoload/scene_manager.gd` — `_poll_progress()` + `_show_overlay()`

Shown only during `"eod"` mode. A 400×18 px `ColorRect` fill bar inside the loading overlay. Polled every 3 s from `pipeline_progress.json`.

Progress animates via a `Tween` on `size.x` toward `BAR_WIDTH * completed / total`. A label below shows `"Generating {npc_name}… (N / total)"`.

On chronicle runs, the progress bar is not shown (no `pipeline_progress.json` is written by `chronicle.py`).

---

*Update this file whenever a system is added, changed, or debugged. Each entry should reflect how the system currently works, not how it was originally designed.*
