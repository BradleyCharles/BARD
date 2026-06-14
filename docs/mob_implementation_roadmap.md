# Mob Expansion — Implementation Roadmap

This document is written for Claude Code, which has full access to the project via the IDE.
Read `docs/game_mechanics.md`, `docs/game_systems.md`, and `docs/project_map.md` before starting.
Execute each phase in order. Do not skip ahead.

---

## Zone & Boss Assignment (Reference)

| Zone | Regular Mobs | Boss | Trigger |
|------|-------------|------|---------|
| Zone A | Orc1, Orc2, Orc3, Plant1, Plant2, Plant3 | Orc3 Boss + Plant3 Boss (independent) | 20 combined orc kills / 20 combined plant kills |
| Zone B | Vampire1, Vampire2, Vampire3 | Vampire3 Boss | 20 combined vampire kills |
| Zone C | Slime1, Slime2, Slime3 | Slime3 Boss | 20 combined slime kills (slime1 + slime2 + slime3) |

---

## Phase 1 — Asset Migration

### Goal
Move Slime sprite folders from `assets/` to `assets/mobs/` to match the folder structure of all new mob assets. Update all path references in GDScript.

### 1.1 — Move Slime Asset Folders (bash)

```bash
mkdir -p assets/mobs
mv assets/Slime1 assets/mobs/Slime1
mv assets/Slime2 assets/mobs/Slime2
mv assets/Slime3 assets/mobs/Slime3
```

After moving, delete any orphaned `.import` sidecar files at the old locations. Godot regenerates these on next editor open. The folders will now be:
- `assets/mobs/Slime1/`
- `assets/mobs/Slime2/`
- `assets/mobs/Slime3/`

### 1.2 — Update ASSET_BASE in All Slime Scripts

Update the `ASSET_BASE` constant in each of the following files:

| File | Old value | New value |
|------|-----------|-----------|
| `mob/slime1.gd` | `"res://assets/Slime1/"` | `"res://assets/mobs/Slime1/"` |
| `mob/slime2.gd` | `"res://assets/Slime2/"` | `"res://assets/mobs/Slime2/"` |
| `mob/slime3.gd` | `"res://assets/Slime3/"` | `"res://assets/mobs/Slime3/"` |
| `mob/slime1_boss.gd` | `"res://assets/Slime1/"` | `"res://assets/mobs/Slime1/"` |
| `mob/slime2_boss.gd` | `"res://assets/Slime2/"` | `"res://assets/mobs/Slime2/"` |
| `mob/slime3_boss.gd` | `"res://assets/Slime3/"` | `"res://assets/mobs/Slime3/"` |

### 1.3 — Manual Step (User)
After Phase 1 is complete, open the Godot editor. It will detect the moved files and prompt reimport. Allow it to complete before running the project.

---

## Phase 2 — Slime System Cleanup

### Goal
Remove slime1_boss and slime2_boss (replaced by a single slime3_boss). Fix the known bug in slime2.gd.

### 2.1 — Fix slime2.gd Contact Bug

In `mob/slime2.gd`, find this line (inside `_physics_process`):
```gdscript
if dist > contact_radius and not _player_is_invincible():
```
Change it to:
```gdscript
if dist > contact_radius:
```
`_player_is_invincible()` is global state — when any mob hits the player, all aggroed slime2s freeze. Removing it fixes this. The player's own iframes prevent re-damage.

### 2.2 — Delete slime1_boss and slime2_boss

Delete these four files entirely:
- `mob/slime1_boss.gd`
- `mob/slime1_boss.tscn`
- `mob/slime2_boss.gd`
- `mob/slime2_boss.tscn`

These are replaced by the single slime3_boss with a combined kill threshold. All references to these files will be removed in Phase 5.

---

## Phase 3 — Attack-Gated Damage (player.gd)

### Goal
New mobs (Orc, Plant, Vampire) only deal damage while their attack animation is playing.
The existing always-on HurtArea contact damage works for slimes and must remain unchanged.
This requires a single backward-compatible check in `player.gd`.

### 3.1 — Add `_is_attacking` Check in player.gd

In `Player/player1/player.gd`, find the `_on_body_entered(body)` function.
At the top of the damage block (after the group check, before reading `body.damage`), add:

```gdscript
# New mobs expose _is_attacking; only deal damage when true.
# Slimes do not have this var — null means always damage (backward compatible).
var mob_attacking = body.get("_is_attacking")
if mob_attacking != null and mob_attacking == false:
    return
```

This means:
- Slimes (no `_is_attacking` var) → `mob_attacking` is null → damage fires normally
- New mobs with `_is_attacking = false` → return early, no damage
- New mobs with `_is_attacking = true` → damage fires

---

## Phase 4 — Regular Mob Scripts

### Shared rules for all new mobs
- Extend `"res://mob/mob_base.gd"` (not RigidBody2D directly)
- Set stats before calling `super._ready()`
- Always guard `_physics_process` with `if _is_hurt: return` at the top
- Call `linear_velocity += _calc_separation()` at the end of `_physics_process`
- Declare `var _is_attacking: bool = false` on all mobs that have walk_attack or run_attack animations
- Use `contact_radius` (inherited, auto-computed) — never define a local CONTACT_RADIUS constant
- Use the same `_build_sprite_frames()` + `_merge_anim()` pattern as the existing slime scripts
- Asset path pattern: `"res://assets/mobs/{MobName}/{AnimName}/{MobName}_{AnimName}_{dir}.aseprite"`

### Stat Table

| Mob | HP | Damage | Knockback | Speed (wander / aggro) | Aggro Radius |
|-----|----|--------|-----------|------------------------|--------------|
| Orc1 | 8 | 2 | 250 | 40 / 280 (charge) | 250 |
| Orc2 | 14 | 3 | 350 | 45 / 320 (charge) | 270 |
| Orc3 | 22 | 4 | 450 | 50 / 360 (charge) | 300 |
| Plant1 | 10 | 2 | 200 | 20 / 35 (creep) | 220 |
| Plant2 | 18 | 3 | 300 | 22 / 40 (creep) | 240 |
| Plant3 | 28 | 5 | 400 | 25 / 45 (creep) | 260 |
| Vampire1 | 6 | 1 | 200 | orbit / 350 (dash) | 300 |
| Vampire2 | 10 | 2 | 300 | orbit / 400 (dash) | 320 |
| Vampire3 | 16 | 3 | 400 | orbit / 450 (dash) | 350 |

---

### 4.1 — Orc1, Orc2, Orc3

**Behavior: The Charger**

The Orc does not stop at `contact_radius`. It charges in a locked direction and passes through the player. Damage fires via the `_is_attacking` flag during the run_attack animation.

**AI States (local enum):**
```
enum OrcPhase { WANDER, CHARGE, RECOVER }
```

**State logic:**
- `WANDER`: Standard wander (walk animation, move/pause timer). On player entering `aggro_radius`, store `_charge_dir = global_position.direction_to(_player_ref.global_position)`, enter `CHARGE`.
- `CHARGE`: Set `linear_velocity = _charge_dir * CHARGE_SPEED`. Play run_attack. Set `_is_attacking = true`. Run for `CHARGE_DURATION = 1.2s` (timer). On timer expiry or zone boundary hit, enter `RECOVER`.
- `RECOVER`: `linear_velocity = Vector2.ZERO`. Play idle. Set `_is_attacking = false`. Wait `RECOVER_DURATION = 0.8s`. Return to `WANDER`.

**Key constants per level:**

| Constant | Orc1 | Orc2 | Orc3 |
|----------|------|------|------|
| `CHARGE_SPEED` | 280 | 320 | 360 |
| `CHARGE_DURATION` | 1.2s | 1.2s | 1.2s |
| `RECOVER_DURATION` | 0.8s | 0.8s | 0.8s |

**Animations used:** idle, walk, run_attack (during charge), hurt, death

**monster_type meta:** `"orc1"` / `"orc2"` / `"orc3"`

**`_integrate_forces`:** Standard zone-boundary clamping (same pattern as slime3). Do not exit CHARGE early when hitting boundary — let `RECOVER` handle it.

---

### 4.2 — Plant1, Plant2, Plant3

**Behavior: The Creeper**

The Plant moves slowly at all times. It never charges. Damage fires via `_is_attacking` while the walk_attack animation plays.

**No custom phase enum needed** — uses mob_base `AIState` (`WANDER_STATE`, `CHASE_STATE`).

**State logic:**
- `WANDER_STATE`: Random slow wander (walk animation). Move/pause timer with longer pauses (2–6s move, 2–5s pause). On player entering `aggro_radius`, switch to `CHASE_STATE`.
- `CHASE_STATE`: Slow creep toward player (walk animation, creep speed). When player distance ≤ `STRIKE_RADIUS`, play walk_attack and set `_is_attacking = true`. Continue moving toward player during walk_attack. When player distance > `STRIKE_RADIUS`, revert to walk and set `_is_attacking = false`. If player leaves `aggro_radius`, return to `WANDER_STATE`.
- No leash/return-to-zone system needed for Plants — use full zone rect as home like slime3.

**Key constants:**

| Constant | All Levels |
|----------|-----------|
| `STRIKE_RADIUS` | 90.0 px |
| `CREEP_SPEED` | wander speed from stat table |
| Wander move time | 2.0–6.0s |
| Wander pause time | 2.0–5.0s |

**`_is_attacking` reset:** Set to false in `_on_animation_finished` when walk_attack completes. walk_attack is a looping animation while in strike range — set it to loop:true and keep `_is_attacking = true` until player leaves STRIKE_RADIUS.

**Animations used:** idle, walk, walk_attack (in strike range during chase), hurt, death

**monster_type meta:** `"plant1"` / `"plant2"` / `"plant3"`

---

### 4.3 — Vampire1, Vampire2, Vampire3

**Behavior: The Stalker**

The Vampire orbits the player at a fixed distance instead of chasing directly. On a timer it dashes straight in with run_attack, then returns to orbit.

**AI States (local enum):**
```
enum VampirePhase { ORBIT, DASH, RECOVER }
```

**State logic:**
- `ORBIT`: Compute the perpendicular vector to `(player_pos - self_pos)` to get the orbit tangent. Set `linear_velocity = tangent * ORBIT_SPEED`. If `_distance_to_player() > ORBIT_RADIUS + 40`: also add an inward component to pull back into orbit range. Play run animation. Dash timer counts down; when it fires, lock `_dash_dir = direction_to_player`, enter `DASH`.
- `DASH`: `linear_velocity = _dash_dir * DASH_SPEED`. Play run_attack. Set `_is_attacking = true`. Run for `DASH_DURATION = 0.4s`. Enter `RECOVER`.
- `RECOVER`: `linear_velocity = Vector2.ZERO`. Play idle. Set `_is_attacking = false`. Wait `RECOVER_DURATION = 0.6s`. Return to `ORBIT`. Reset dash timer to `randf_range(DASH_INTERVAL_MIN, DASH_INTERVAL_MAX)`.

**Key constants:**

| Constant | Vampire1 | Vampire2 | Vampire3 |
|----------|----------|----------|----------|
| `ORBIT_RADIUS` | 200 | 200 | 200 |
| `ORBIT_SPEED` | 90 | 100 | 110 |
| `DASH_SPEED` | 350 | 400 | 450 |
| `DASH_DURATION` | 0.4s | 0.4s | 0.4s |
| `DASH_INTERVAL_MIN` | 3.0s | 2.5s | 2.0s |
| `DASH_INTERVAL_MAX` | 5.0s | 4.0s | 3.5s |

**Orbit implementation note:** In `_physics_process`, compute:
```gdscript
var to_player := _player_ref.global_position - global_position
var dist := to_player.length()
var tangent := Vector2(-to_player.y, to_player.x).normalized()
var radial := to_player.normalized() * (dist - ORBIT_RADIUS) * 0.05
linear_velocity = (tangent * ORBIT_SPEED) + radial
```
The `radial` term gently pulls the vampire toward the correct orbit distance without snapping.

**Animations used:** idle, run (orbiting), run_attack (during dash), hurt, death

**monster_type meta:** `"vampire1"` / `"vampire2"` / `"vampire3"`

---

### 4.4 — Scene Files (.tscn) for All Regular Mobs

Create one `.tscn` per mob (12 total). Each follows the same structure as `mob/slime2.tscn`:

```
[RigidBody2D]  gravity_scale=0  lock_rotation=true  script=<mob_script>
  [AnimatedSprite2D]  scale=Vector2(2,2)
  [CollisionShape2D]  shape=CircleShape2D(radius=26)
  [VisibleOnScreenNotifier2D]
```

Use `scale=Vector2(2,2)` on AnimatedSprite2D for all regular mobs. `CollisionShape2D` radius stays at 26 — `body_radius` is auto-computed from this in `mob_base._ready()`.

---

## Phase 5 — Boss Scripts

All bosses extend `"res://mob/mob_base.gd"`. Use scale `Vector2(3,3)` on AnimatedSprite2D (same as existing slime bosses). Boss `CollisionShape2D` radius = 40.

All bosses implement `_reset_modulate()` override returning `Color.WHITE` (same as slime bosses).

---

### 5.1 — Slime3 Boss — Refactor Only

**No behavior changes.** The existing `mob/slime3_boss.gd` and `mob/slime3_boss.tscn` are kept as-is.

Only change: the `SceneManager.earn_slime_goop()` call in `_on_died()`. Decide on the goop value for the combined-zone boss (suggest 20 — same as the current slime3 boss).

---

### 5.2 — Orc3 Boss

**File:** `mob/orc3_boss.gd` + `mob/orc3_boss.tscn`

**Stats:** HP=60, Damage=6, Knockback=600, `BOSS_SPEED=70`

**Behavior: Telegraphed Charge**

```
enum OrcBossPhase { NORMAL, TELEGRAPH, CHARGE, RECOVER }
```

- `NORMAL`: Chase player using `_direction_to_player_with_noise(BOSS_SPEED)`. Play run. When `_attack_cooldown <= 0` and player is within `CHARGE_TRIGGER_RADIUS = 350px`, enter `TELEGRAPH`.
- `TELEGRAPH`: `linear_velocity = Vector2.ZERO`. Stop and face player (update `facing` toward player). Play idle (facing player). Draw a visible directional arrow or highlight via `queue_redraw()` showing the locked charge direction. `_telegraph_timer` counts up for `TELEGRAPH_DURATION = 1.5s`. Lock `_charge_dir` at the moment TELEGRAPH starts.
- `CHARGE`: `linear_velocity = _charge_dir * CHARGE_SPEED (500px/s)`. Set `_is_attacking = true`. Play run_attack. `_charge_timer` counts up for `CHARGE_DURATION = 1.0s` OR until zone boundary. Enter `RECOVER`.
- `RECOVER`: `linear_velocity = Vector2.ZERO`. Set `_is_attacking = false`. Play idle. `_recover_timer` counts for `RECOVER_DURATION = 1.0s`. Return to `NORMAL`. Set `_attack_cooldown = ATTACK_COOLDOWN (5.0s)`.

**`_draw()`:** During TELEGRAPH phase, draw a semi-transparent orange rectangle extending `CHARGE_SPEED * CHARGE_DURATION` px in `_charge_dir` from the boss center. Width ~40px. Fades in over the telegraph duration.

**`take_damage` override:** During CHARGE and TELEGRAPH phases, still take damage. Hurt animation only plays in NORMAL and RECOVER phases. In CHARGE, knockback impulse applies but `_is_hurt` is not set (preserve charge momentum feel).

**`_on_died()`:** `SceneManager.earn_slime_goop(15)` (tunable).

**monster_type meta:** `"orc3_boss"`

---

### 5.3 — Plant3 Boss

**File:** `mob/plant3_boss.gd` + `mob/plant3_boss.tscn`

**Stats:** HP=50, Damage=7, Knockback=500

**Behavior: Starburst AOE**

```
enum PlantBossPhase { CREEP, TELEGRAPH, FIRE }
```

- `CREEP`: Slow creep toward player (walk animation, speed=30px/s). Always moving. When `_attack_cooldown <= 0` and player within `ATTACK_TRIGGER_RADIUS = 400px`, enter `TELEGRAPH`.
- `TELEGRAPH`: `linear_velocity = Vector2.ZERO`. Stop. Pick `_beam_start_angle = randf() * TAU`. `_telegraph_timer` counts up for `TELEGRAPH_DURATION = 2.0s`. Call `queue_redraw()` each frame to draw the expanding beam warning. Enter `FIRE` when timer completes.
- `FIRE`: Apply starburst hit check (see below). Play attack animation briefly. `queue_redraw()` to clear beams. Return to `CREEP`. Set `_attack_cooldown = ATTACK_COOLDOWN (6.0s)`.

**`_draw()` — Starburst Telegraph:**
Draw 5 semi-transparent orange rectangles radiating from `Vector2.ZERO` (boss local origin):
```gdscript
func _draw() -> void:
    if _boss_phase != PlantBossPhase.TELEGRAPH:
        return
    var alpha := _telegraph_timer / TELEGRAPH_DURATION
    for i in 5:
        var angle := _beam_start_angle + i * (TAU / 5.0)
        var beam_dir := Vector2(cos(angle), sin(angle))
        # Draw as a rotated rect centered along beam_dir
        var half_w := BEAM_HALF_WIDTH  # 20.0 px
        var length := BEAM_REACH       # 400.0 px
        draw_set_transform(Vector2.ZERO, angle, Vector2.ONE)
        draw_rect(Rect2(0.0, -half_w, length, half_w * 2.0),
                  Color(1.0, 0.5, 0.0, 0.35 * alpha))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)  # reset
```

**Starburst hit detection (called from FIRE state):**
```gdscript
func _check_starburst_hit() -> void:
    if _player_ref == null or not is_instance_valid(_player_ref):
        return
    if _distance_to_player() > BEAM_REACH:
        return
    var angle_to_player := (global_position.direction_to(
            _player_ref.global_position)).angle()
    for i in 5:
        var beam_center := _beam_start_angle + i * (TAU / 5.0)
        var diff := absf(wrapf(angle_to_player - beam_center, -PI, PI))
        if diff <= BEAM_HALF_WIDTH_RADIANS:  # ~0.35 rad (~20 degrees)
            var kb_dir := (_player_ref.global_position - global_position).normalized()
            _player_ref.call_deferred("take_damage",
                    AOE_DAMAGE, kb_dir * AOE_KNOCKBACK)
            return
```

**Constants:**
```gdscript
const BEAM_REACH             : float = 400.0
const BEAM_HALF_WIDTH        : float = 20.0   # px, for drawing
const BEAM_HALF_WIDTH_RADIANS: float = 0.35   # ~20 degrees, for hit check
const AOE_DAMAGE             : int   = 7
const AOE_KNOCKBACK          : float = 500.0
const ATTACK_COOLDOWN        : float = 6.0
const TELEGRAPH_DURATION     : float = 2.0
const ATTACK_TRIGGER_RADIUS  : float = 400.0
```

**`_on_died()`:** `SceneManager.earn_slime_goop(15)` (tunable).

**monster_type meta:** `"plant3_boss"`

---

### 5.4 — Vampire3 Boss

**File:** `mob/vampire3_boss.gd` + `mob/vampire3_boss.tscn`

**Stats:** HP=40, Damage=5, Knockback=400

**Behavior: Orbit + Life Drain**

```
enum VampireBossPhase { ORBIT, DASH, RECOVER }
```

Same orbit/dash/recover pattern as the regular vampire (see Phase 4.3) but with these differences:

- **Faster orbit and dash:** `ORBIT_SPEED=130`, `DASH_SPEED=500`, `DASH_DURATION=0.35s`
- **Tighter dash interval:** `DASH_INTERVAL_MIN=2.0s`, `DASH_INTERVAL_MAX=3.5s`
- **Life drain on hit:** In `_on_body_entered` or by overriding `take_damage` on the player side, when the boss's dash connects, heal the boss. Implement this by checking `_is_attacking` after `_player_ref.call_deferred("take_damage", ...)` fires, then calling:
  ```gdscript
  health = mini(health + DRAIN_HEAL_AMOUNT, max_health)
  ```
  The cleanest place to trigger this is inside the vampire boss's `_physics_process` when the boss body overlaps the player during a DASH — check `_distance_to_player() <= contact_radius and _is_attacking`. Heal once per dash (use a `_healed_this_dash: bool` flag, reset on each new DASH).
- **Health bar update:** The `boss_health_bar.gd` already polls health every frame, so healing will reflect automatically.

**`DRAIN_HEAL_AMOUNT`:** 4 HP per dash that connects.

**`_on_died()`:** `SceneManager.earn_slime_goop(15)` (tunable).

**monster_type meta:** `"vampire3_boss"`

---

### 5.5 — Boss Scene Files (.tscn)

Create three boss `.tscn` files. Follow the structure of `mob/slime3_boss.tscn`:

```
[RigidBody2D]  gravity_scale=0  lock_rotation=true  script=<boss_script>
  [AnimatedSprite2D]  scale=Vector2(3,3)
  [CollisionShape2D]  shape=CircleShape2D(radius=40)
  [VisibleOnScreenNotifier2D]
```

Files to create:
- `mob/orc3_boss.tscn`
- `mob/plant3_boss.tscn`
- `mob/vampire3_boss.tscn`

---

## Phase 6 — field.gd Refactor

### 6.1 — Remove Old Slime Boss Export Vars

Remove these two `@export` vars and all references to them throughout `field.gd`:
```gdscript
@export var slime1_boss_scene: PackedScene
@export var slime2_boss_scene: PackedScene
```

### 6.2 — Add New Mob Export Vars

Add the following `@export` vars to `field.gd`. These must be assigned in the Godot editor inspector after this phase (see Phase 7):

```gdscript
# Zone A
@export var orc1_scene   : PackedScene
@export var orc2_scene   : PackedScene
@export var orc3_scene   : PackedScene
@export var orc3_boss_scene : PackedScene
@export var plant1_scene : PackedScene
@export var plant2_scene : PackedScene
@export var plant3_scene : PackedScene
@export var plant3_boss_scene : PackedScene

# Zone B
@export var vampire1_scene : PackedScene
@export var vampire2_scene : PackedScene
@export var vampire3_scene : PackedScene
@export var vampire3_boss_scene : PackedScene
```

### 6.3 — Refactor Boss Trigger System

Replace the current per-type slime kill counters and `_check_boss_triggers()` function entirely.

**Remove:**
```gdscript
var _slime1_killed : int = 0
var _slime2_killed : int = 0
var _slime3_killed : int = 0
var _slime1_boss_spawned : bool = false
var _slime2_boss_spawned : bool = false
var _slime3_boss_spawned : bool = false
```

**Replace with:**
```gdscript
# Zone C — combined slime kill counter
var _zone_c_slime_killed   : int  = 0
var _slime3_boss_spawned   : bool = false

# Zone A — independent orc and plant counters
var _zone_a_orc_killed     : int  = 0
var _zone_a_plant_killed   : int  = 0
var _orc3_boss_spawned     : bool = false
var _plant3_boss_spawned   : bool = false

# Zone B — combined vampire kill counter
var _zone_b_vampire_killed : int  = 0
var _vampire3_boss_spawned : bool = false
```

**Refactor `_on_mob_died(mob_body)`:**

Replace the per-type kill counter increment block with a routing block based on `monster_type` meta:

```gdscript
match monster_type:
    "slime1", "slime2", "slime3":
        _zone_c_slime_killed += 1
    "orc1", "orc2", "orc3":
        _zone_a_orc_killed += 1
    "plant1", "plant2", "plant3":
        _zone_a_plant_killed += 1
    "vampire1", "vampire2", "vampire3":
        _zone_b_vampire_killed += 1
```

**Refactor `_check_boss_triggers()`:**

```gdscript
func _check_boss_triggers() -> void:
    # Zone C — Slime3 Boss
    if not _slime3_boss_spawned and _zone_c_slime_killed >= BOSS_KILL_THRESHOLD:
        _slime3_boss_spawned = true
        call_deferred("_spawn_boss", slime3_boss_scene)

    # Zone A — Orc3 Boss
    if not _orc3_boss_spawned and _zone_a_orc_killed >= BOSS_KILL_THRESHOLD:
        _orc3_boss_spawned = true
        call_deferred("_spawn_boss", orc3_boss_scene)

    # Zone A — Plant3 Boss
    if not _plant3_boss_spawned and _zone_a_plant_killed >= BOSS_KILL_THRESHOLD:
        _plant3_boss_spawned = true
        call_deferred("_spawn_boss", plant3_boss_scene)

    # Zone B — Vampire3 Boss
    if not _vampire3_boss_spawned and _zone_b_vampire_killed >= BOSS_KILL_THRESHOLD:
        _vampire3_boss_spawned = true
        call_deferred("_spawn_boss", vampire3_boss_scene)
```

`_spawn_boss(scene: PackedScene)` already exists and handles instantiation + boss_health_bar. No changes needed to that function.

### 6.4 — Update `_spawn_bounty_mob()` Scene Routing

`_spawn_bounty_mob(monster_type, zone)` maps a monster_type string to a scene. Add the new types:

```gdscript
"orc1":    orc1_scene
"orc2":    orc2_scene
"orc3":    orc3_scene
"plant1":  plant1_scene
"plant2":  plant2_scene
"plant3":  plant3_scene
"vampire1": vampire1_scene
"vampire2": vampire2_scene
"vampire3": vampire3_scene
```

---

## Phase 7 — Data Updates

### 7.1 — bounty_pool.json

The current bounty_pool.json assigns slimes to zones a/b/c. Update all slime entries to `zone_c`. Then add new entries for orcs, plants, and vampires.

**Updated slime entries (zone change only):**
```json
{ "id": "slime1_zone_c_small",  "monster_type": "slime1", "zone": "zone_c", "quantity": 5,  "flavor": "...", "reward_text": "..." },
{ "id": "slime1_zone_c_medium", "monster_type": "slime1", "zone": "zone_c", "quantity": 10, "flavor": "...", "reward_text": "..." },
{ "id": "slime1_zone_c_large",  "monster_type": "slime1", "zone": "zone_c", "quantity": 20, "flavor": "...", "reward_text": "..." },
{ "id": "slime2_zone_c_small",  "monster_type": "slime2", "zone": "zone_c", "quantity": 5,  "flavor": "...", "reward_text": "..." },
{ "id": "slime2_zone_c_medium", "monster_type": "slime2", "zone": "zone_c", "quantity": 10, "flavor": "...", "reward_text": "..." },
{ "id": "slime2_zone_c_large",  "monster_type": "slime2", "zone": "zone_c", "quantity": 20, "flavor": "...", "reward_text": "..." },
{ "id": "slime3_zone_c_small",  "monster_type": "slime3", "zone": "zone_c", "quantity": 5,  "flavor": "...", "reward_text": "..." },
{ "id": "slime3_zone_c_medium", "monster_type": "slime3", "zone": "zone_c", "quantity": 10, "flavor": "...", "reward_text": "..." },
{ "id": "slime3_zone_c_large",  "monster_type": "slime3", "zone": "zone_c", "quantity": 20, "flavor": "...", "reward_text": "..." }
```

**New Zone A entries (orc + plant):**
Fill in flavor and reward_text with appropriate lore. Quantities match existing tier pattern (5/10/20).
```json
{ "id": "orc1_zone_a_small",   "monster_type": "orc1",   "zone": "zone_a", "quantity": 5  },
{ "id": "orc1_zone_a_medium",  "monster_type": "orc1",   "zone": "zone_a", "quantity": 10 },
{ "id": "orc1_zone_a_large",   "monster_type": "orc1",   "zone": "zone_a", "quantity": 20 },
{ "id": "orc2_zone_a_small",   "monster_type": "orc2",   "zone": "zone_a", "quantity": 5  },
{ "id": "orc2_zone_a_medium",  "monster_type": "orc2",   "zone": "zone_a", "quantity": 10 },
{ "id": "orc2_zone_a_large",   "monster_type": "orc2",   "zone": "zone_a", "quantity": 20 },
{ "id": "orc3_zone_a_small",   "monster_type": "orc3",   "zone": "zone_a", "quantity": 5  },
{ "id": "orc3_zone_a_medium",  "monster_type": "orc3",   "zone": "zone_a", "quantity": 10 },
{ "id": "orc3_zone_a_large",   "monster_type": "orc3",   "zone": "zone_a", "quantity": 20 },
{ "id": "plant1_zone_a_small", "monster_type": "plant1", "zone": "zone_a", "quantity": 5  },
{ "id": "plant1_zone_a_medium","monster_type": "plant1", "zone": "zone_a", "quantity": 10 },
{ "id": "plant1_zone_a_large", "monster_type": "plant1", "zone": "zone_a", "quantity": 20 },
{ "id": "plant2_zone_a_small", "monster_type": "plant2", "zone": "zone_a", "quantity": 5  },
{ "id": "plant2_zone_a_medium","monster_type": "plant2", "zone": "zone_a", "quantity": 10 },
{ "id": "plant2_zone_a_large", "monster_type": "plant2", "zone": "zone_a", "quantity": 20 },
{ "id": "plant3_zone_a_small", "monster_type": "plant3", "zone": "zone_a", "quantity": 5  },
{ "id": "plant3_zone_a_medium","monster_type": "plant3", "zone": "zone_a", "quantity": 10 },
{ "id": "plant3_zone_a_large", "monster_type": "plant3", "zone": "zone_a", "quantity": 20 }
```

**New Zone B entries (vampire):**
```json
{ "id": "vampire1_zone_b_small",  "monster_type": "vampire1", "zone": "zone_b", "quantity": 5  },
{ "id": "vampire1_zone_b_medium", "monster_type": "vampire1", "zone": "zone_b", "quantity": 10 },
{ "id": "vampire1_zone_b_large",  "monster_type": "vampire1", "zone": "zone_b", "quantity": 20 },
{ "id": "vampire2_zone_b_small",  "monster_type": "vampire2", "zone": "zone_b", "quantity": 5  },
{ "id": "vampire2_zone_b_medium", "monster_type": "vampire2", "zone": "zone_b", "quantity": 10 },
{ "id": "vampire2_zone_b_large",  "monster_type": "vampire2", "zone": "zone_b", "quantity": 20 },
{ "id": "vampire3_zone_b_small",  "monster_type": "vampire3", "zone": "zone_b", "quantity": 5  },
{ "id": "vampire3_zone_b_medium", "monster_type": "vampire3", "zone": "zone_b", "quantity": 10 },
{ "id": "vampire3_zone_b_large",  "monster_type": "vampire3", "zone": "zone_b", "quantity": 20 }
```

### 7.2 — pipeline/nl_descriptors.py

Add kill descriptor functions for each new mob family. Follow the exact pattern of `describe_slime_kills(n)`. Add:

- `describe_orc_kills(n: int) -> str`
- `describe_plant_kills(n: int) -> str`
- `describe_vampire_kills(n: int) -> str`

Each should have the same tier buckets (0, 1, 2–3, 4–7, 8–12, 13–20, 20+) with thematically appropriate phrasing for the creature type. Orcs: aggressive, brutish. Plants: creeping, encroaching. Vampires: predatory, evasive.

Also update `describe_field_activity()` and any function that currently enumerates monster types to include the new type strings `"orc1"/"orc2"/"orc3"`, `"plant1"/"plant2"/"plant3"`, `"vampire1"/"vampire2"/"vampire3"`.

---

## Phase 8 — Editor Steps (Manual — done by you in Godot)

After all script and scene files are created, open the Godot editor and complete these steps:

1. **Allow reimport** — Godot will detect moved slime assets and reimport them automatically. Confirm the reimport dialog.

2. **Assign export vars on field.tscn** — Select the `Field` node in `world/field.tscn`. In the Inspector, assign every new `@export` PackedScene var to its matching `.tscn` file:
   - `orc1_scene` → `mob/orc1.tscn`
   - `orc2_scene` → `mob/orc2.tscn`
   - `orc3_scene` → `mob/orc3.tscn`
   - `orc3_boss_scene` → `mob/orc3_boss.tscn`
   - `plant1_scene` → `mob/plant1.tscn`
   - `plant2_scene` → `mob/plant2.tscn`
   - `plant3_scene` → `mob/plant3.tscn`
   - `plant3_boss_scene` → `mob/plant3_boss.tscn`
   - `vampire1_scene` → `mob/vampire1.tscn`
   - `vampire2_scene` → `mob/vampire2.tscn`
   - `vampire3_scene` → `mob/vampire3.tscn`
   - `vampire3_boss_scene` → `mob/vampire3_boss.tscn`
   - Remove the old `slime1_boss_scene` and `slime2_boss_scene` assignments (vars no longer exist)

3. **Verify slime asset paths** — Open one of the slime scenes (e.g. `slime1.tscn`) and confirm the AnimatedSprite2D loads without errors. If Godot reports missing textures, confirm the `assets/mobs/Slime1/` folder exists and the ASSET_BASE in `slime1.gd` is correct.

---

## File Creation Summary

### New Files
```
mob/orc1.gd           mob/orc1.tscn
mob/orc2.gd           mob/orc2.tscn
mob/orc3.gd           mob/orc3.tscn
mob/orc3_boss.gd      mob/orc3_boss.tscn
mob/plant1.gd         mob/plant1.tscn
mob/plant2.gd         mob/plant2.tscn
mob/plant3.gd         mob/plant3.tscn
mob/plant3_boss.gd    mob/plant3_boss.tscn
mob/vampire1.gd       mob/vampire1.tscn
mob/vampire2.gd       mob/vampire2.tscn
mob/vampire3.gd       mob/vampire3.tscn
mob/vampire3_boss.gd  mob/vampire3_boss.tscn
```

### Modified Files
```
mob/slime2.gd               — remove _player_is_invincible() check
mob/slime1.gd               — update ASSET_BASE path
mob/slime2.gd               — update ASSET_BASE path
mob/slime3.gd               — update ASSET_BASE path
mob/slime1_boss.gd          — update ASSET_BASE path (kept for reference until Phase 2 deletes it)
mob/slime2_boss.gd          — update ASSET_BASE path (kept for reference until Phase 2 deletes it)
mob/slime3_boss.gd          — update ASSET_BASE path
Player/player1/player.gd    — add _is_attacking gate in _on_body_entered
world/field.gd              — new export vars, refactored boss triggers, spawn routing
data/bounty_pool.json       — zone reassignment + new mob entries
pipeline/nl_descriptors.py  — new kill descriptor functions
```

### Deleted Files
```
mob/slime1_boss.gd
mob/slime1_boss.tscn
mob/slime2_boss.gd
mob/slime2_boss.tscn
```
