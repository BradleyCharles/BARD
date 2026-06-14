# BARD — Game Mechanics Reference

**Live document.** Update this file whenever a mechanic is added, changed, or debugged.  
It exists so the collision model, damage flow, and AI rules never have to be reverse-engineered from scratch.

---

## Collision Layer Map

Godot 2D physics uses 32 bit-flag layers. Only layers with names assigned in **Project → Project Settings → Layer Names → 2D Physics** are in use. Values below are the integer bitmasks passed to `collision_layer` / `collision_mask`.

| Layer # | Bitmask value | Name (in Project Settings) | Used by |
|---------|--------------|----------------------------|---------|
| 1 | 1 | `mobs` | World geometry / static environment |
| 2 | 2 | `player` | Player CharacterBody2D; NPC DetectionArea layer |
| 3 | 4 | `npc_detection` | NPC proximity Area2D scans |
| 4 | 8 | *(unnamed)* | All mob RigidBody2D bodies; all NPC StaticBody2D blockers |

**Rule:** layers 1–3 pre-existed. Layer 4 (value `8`) was added for the "entity bodies" layer — everything that should be physically solid but must not push anything.

---

## Entity Collision Settings

### Player — `Player/player.gd` + `Player/player.tscn`

| Node | Type | `collision_layer` | `collision_mask` | Purpose |
|------|------|-------------------|------------------|---------|
| Player (root) | CharacterBody2D | 2 | **1** | Blocked by world geometry only; set in `_ready()` |
| SwordHitbox | Area2D | 0 | **8** | Detects mob bodies on layer 8; `body_entered` → `_on_sword_hit` |
| HurtArea | Area2D | 2 | **8** | Detects mob bodies on layer 8 via `CircleShape2D(r=14)`; `body_entered` → `_on_body_entered` |

All masks are set **in code** in `player.gd:_ready()`, overriding `.tscn` defaults.

**Why `collision_mask = 1` (world only):** Godot 4's `CharacterBody2D.move_and_slide()` runs a recovery step every frame that pushes the character out of any overlapping shape on its mask. Including mob bodies (layer 8) in the mask meant `move_and_slide()` recovery would push the player away from any mob it overlapped — even when the mob had zero velocity. Removing mobs from the mask eliminates this entirely.

**How blocking still works:** `_block_mob_movement(vel)` in `player.gd` cancels any velocity component pointing toward a mob within `body_radius + _PLAYER_RADIUS` distance, before `move_and_slide()` is called. This is purely script-level — no physics recovery, no pushing.

### Mobs — `mob/mob_base.gd`

| Property | Value | Reason |
|----------|-------|--------|
| `collision_layer` | **8** | Visible on entity layer; detectable by player's HurtArea and SwordHitbox |
| `collision_mask` | **1** | Detects world geometry (rocks, trees, static obstacles) — blocked by the same layer as the player |

Set unconditionally in `mob_base._ready()`, inherited by all mob subclasses.

**Key rule:** mask=1 (world geometry only) blocks mobs on rocks and trees without introducing mob-player or mob-mob pushing. Those are on layers 2 and 8 respectively — not in the mask — so mutual constraint forces never apply between mobs and the player.

**Hitbox radii:** Defined as constants in `mob_base.gd` (`HITBOX_SLIME1` … `HITBOX_VAMPIRE3`). Each mob calls `_apply_hitbox(HITBOX_X)` in `_ready()` after `super._ready()`. This overrides the scene-file CircleShape2D radius and updates `body_radius` and `contact_radius` in one call. To tune, change the constant in `mob_base.gd`.

### NPCs — `npc/npc_base.gd` (`_add_physics_body()`)

Only **non-wandering NPCs** (named characters) get a `StaticBody2D` child. Wandering background NPCs have no physics body.

| Property | Value | Reason |
|----------|-------|--------|
| `collision_layer` | **8** | Same entity layer as mobs — player's mask 9 is blocked by it |
| `collision_mask` | **0** | StaticBody2D is immovable by definition; mask 0 prevents any force feedback |
| Shape | `CircleShape2D`, radius 12 | Approximate NPC footprint |

Named NPCs (innkeeper, blacksmith, guild commander) are stationary; their static body blocks the player without pushing. Wandering NPCs have no body — player can pass through them — because a `StaticBody2D` that moves between frames reports its apparent velocity to the physics server and actively pushes `CharacterBody2D` bodies it overlaps.

---

## Damage Flow

### Player taking damage from mobs

```
Mob RigidBody2D (layer 8) enters player HurtArea (mask 8)
  → HurtArea.body_entered fires
  → player._on_body_entered(body)
      checks: body.is_in_group("ground_mobs") or "flying_mobs"
      reads: body.damage, body.knockback_force
      calls: self.take_damage(mob_damage, kb_dir * mob_kb_force)  [deferred]
  → player.take_damage(amount, knockback)
      • health -= amount
      • SceneManager.set_player_health(health)
      • sets _iframes = PlayerStats.IFRAME_TIME (1.0 s)
      • sets _knockback_vel, _knockback_time = PlayerStats.KNOCKBACK_DURATION
      • plays "hurt" animation; on finish plays "death" if health ≤ 0
```

**Invincibility frames:** 1.0 s after any hit. `_iframes` is counted down in `_process`. A second `take_damage` call is a no-op while `_iframes > 0`.

### Player dealing damage to mobs (sword)

```
SwordHitbox Area2D (mask 8) is monitoring only on animation frames 2–6
  → body_entered fires when mob RigidBody2D (layer 8) enters hitbox
  → player._on_sword_hit(body)
      checks: body.is_in_group("ground_mobs") or "flying_mobs"
      reads active weapon stats from _weapon_stats[active_weapon]
      computes: knockback = (body.pos - player.pos).normalized() * KNOCKBACK
      calls: body.take_damage(damage, knockback)
  → mob_base.take_damage(amount, knockback_vec)
      • health -= amount
      • apply_central_impulse(knockback_vec)  ← physics impulse
      • sets _hurt_timer = 0.15 s (red flash)
      • calls _on_died() if health ≤ 0
```

**Knockback working condition:** mob subclasses (slime1, slime3) override `_physics_process` and were found to immediately reassign `linear_velocity` each frame, overriding the impulse. Fix: both subclasses now `return` early from `_physics_process` when `_is_hurt == true`, letting the impulse carry the mob for the duration of the hurt animation.

**Weapon stats (tuning knobs):**

| Weapon | DAMAGE | KNOCKBACK | SWING_FPS | Hitbox | HITBOX_OFFSET |
|--------|--------|-----------|-----------|--------|---------------|
| Sword | 1 | 300.0 | 30.0 | 60×40 px | 60.0 px |
| Axe | 2 | 600.0 | 15.0 | 35×70 px | 60.0 px |

Defined in `Player/weapons/sword_data.gd` and `axe_data.gd`.

---

## Mob AI

### Shared base — `mob/mob_base.gd`

All mobs extend `RigidBody2D`. Movement is set via `linear_velocity` directly each physics frame. Boundary clamping is done manually in `_integrate_forces()` — mobs do not rely on physics wall collision.

**`body_radius`:** Auto-computed in `_ready()` from the mob's `CircleShape2D` radius × `scale.x`. Used by `_block_mob_movement()` in the player and `_calc_separation()` for mob-mob spacing. Automatically accounts for any tscn scale changes.

**`_calc_separation()`:** Returns a push vector away from any overlapping mob. Each subclass calls `linear_velocity += _calc_separation()` at the end of `_physics_process`. Prevents stacking.

**Signals:** `died(mob: Node)` — emitted before `queue_free()`, connected by `field.gd` at spawn time.

**`take_damage(amount, knockback_vec)`:** Applies impulse, flashes red for 0.15 s, kills if health ≤ 0.

### Slime1 — `mob/slime1.gd`

- **Personality:** PACK_MENTALITY. Flees alone; chases when ≥ 2 nearby slime1 within 200 px.
- **Health:** 3. **Aggro radius:** 300 px.
- **Pack link:** on aggro, calls `trigger_aggro()` on nearby slime1s (chain reaction). Re-scans every 0.5 s.
- **Contact stop:** when in CHASE_STATE and within `CONTACT_RADIUS = 44.0` px of player, sets `linear_velocity = Vector2.ZERO` and plays idle. Prevents mob from driving through player.
- **Hurt bypass:** `_physics_process` returns early when `_is_hurt == true` — allows knockback impulse to work.

### Slime3 — `mob/slime3.gd`

- **Personality:** WEAK_AGGRESSIVE. Chases solo when player within 250 px.
- **Health:** 8. **Damage:** 2.
- **Contact stop:** same `CONTACT_RADIUS = 44.0` px logic as slime1.
- **Hurt bypass:** same early-return pattern as slime1.
- **Previously broken:** had explicit player-separation code in `_integrate_forces()` that kept the mob ≥ 60 px from the player, preventing `HurtArea.body_entered` from ever firing (mob never reached the player). Removed.

### Contact Radius

`contact_radius` is a `var` on `mob_base.gd`, computed automatically in `_ready()` as:

```
contact_radius = body_radius + 20.0   # 20 px = player capsule effective radius at scale 2
```

Because `body_radius` is derived from `CircleShape2D.radius × scale.x`, `contact_radius` automatically adjusts when a mob's tscn scale changes — no manual constant to update. All slime subclasses use `contact_radius` (not a local const) so the value is always in sync with the actual collision geometry.

### Contact Stop

All slimes stop (`linear_velocity = Vector2.ZERO`) when within `contact_radius` of the player and chase when further. Player iframes prevent re-damage if a mob re-enters the hurt area, so no mob-side iframe check is needed. The previous pattern (`dist > contact_radius and not _player_is_invincible()`) was a bug: `_player_is_invincible()` is global state, so any mob hitting the player caused ALL mobs to stop rather than just the one at contact range.

### Orc1/2/3 — `mob/orc1.gd`, `mob/orc2.gd`, `mob/orc3.gd`

Charger AI. Three phases (local enum `OrcPhase`):
- **WANDER**: Random walk. On player entering `aggro_radius`, locks `_charge_dir` and enters CHARGE.
- **CHARGE**: `linear_velocity = _charge_dir * CHARGE_SPEED`. Plays run_attack. `_is_attacking = true`. CHARGE_DURATION=1.2 s, then RECOVER.
- **RECOVER**: `linear_velocity = Vector2.ZERO`. `_is_attacking = false`. RECOVER_DURATION=0.8 s, then WANDER.

Does not stop at `contact_radius` — passes through the player during the charge. Damage fires via `_is_attacking` gate in `player.gd`.

**Charge trigger:** orcs enter CHARGE only when `dist < CHARGE_TRIGGER_RADIUS` (140 px, defined per-script), not at full `aggro_radius`. This prevents charges from starting off-screen distance. Once `_is_aggroed = true` (set when first charge begins), the orc keeps re-triggering charges but still requires the player to re-enter `CHARGE_TRIGGER_RADIUS` after each recovery — they do not actively pursue between charges.

Stats: Orc1 HP=8 dmg=2 kb=250 speed=280; Orc2 HP=14 dmg=3 kb=350 speed=320; Orc3 HP=22 dmg=4 kb=450 speed=360.

### Plant1/2/3 — `mob/plant1.gd`, `mob/plant2.gd`, `mob/plant3.gd`

Creeper AI. Uses mob_base `AIState` (WANDER_STATE / CHASE_STATE):
- **WANDER_STATE**: Slow random movement (2–6 s move, 2–5 s pause). On player within `aggro_radius`, enters CHASE.
- **CHASE_STATE**: Slow creep toward player. When `dist <= STRIKE_RADIUS=90 px`, plays walk_attack and sets `_is_attacking = true`. When `dist > STRIKE_RADIUS`, reverts to walk, `_is_attacking = false`. On player leaving `aggro_radius`, returns to WANDER.

walk_attack loops while in strike range. Damage fires via `_is_attacking` gate in `player.gd`.

Stats: Plant1 HP=10 dmg=2 kb=200; Plant2 HP=18 dmg=3 kb=300; Plant3 HP=28 dmg=5 kb=400.

### Plant1/2/3 — permanent aggro
Once `dist < aggro_radius` triggers CHASE_STATE, `_is_aggroed = true` is set. The `_is_aggroed or dist < aggro_radius` check means the plant never drops back to WANDER even if the player runs away. Plants chase until killed.

### Vampire1/2/3 — `mob/vampire1.gd`, `mob/vampire2.gd`, `mob/vampire3.gd`

Stalker AI. Three phases (local enum `VampirePhase`):
- **ORBIT**: Orbits player at `ORBIT_RADIUS=200 px`. Tangent velocity keeps orbit; radial term pulls toward correct radius. Plays run.
- **DASH**: `linear_velocity = _dash_dir * DASH_SPEED`. `_is_attacking = true`. DASH_DURATION=0.4 s, then RECOVER.
- **RECOVER**: `linear_velocity = Vector2.ZERO`. `_is_attacking = false`. RECOVER_DURATION=0.6 s, back to ORBIT. Dash timer reset to `randf_range(DASH_INTERVAL_MIN, DASH_INTERVAL_MAX)`.

Orbit formula:
```gdscript
var tangent := Vector2(-to_player.y, to_player.x).normalized()
var radial  := to_player.normalized() * (dist - ORBIT_RADIUS) * 0.05
linear_velocity = (tangent * ORBIT_SPEED) + radial
```
Damage fires via `_is_attacking` gate in `player.gd`. Vampires orbit immediately on spawn (no aggro_radius check needed — they always have player_ref). `z_index = 4` so they render above the Decor0 layer (z_index 3), appearing to fly over trees and rocks. `collision_mask = 0` (set after `super._ready()` in each vampire script) so they pass through world geometry (crystals, rocks) rather than being blocked by it.

Stats: V1 HP=6 dmg=1 kb=200 orbit=90 dash=350 interval=3.0–5.0 s; V2 HP=10 dmg=2 kb=300 orbit=100 dash=400 interval=2.5–4.0 s; V3 HP=16 dmg=3 kb=400 orbit=110 dash=450 interval=2.0–3.5 s.

### _is_attacking Gate (player.gd `_on_body_entered`)

New mob types (orcs, plants, vampires) declare `var _is_attacking: bool = false`. `player.gd._on_body_entered` reads this before processing damage:

```gdscript
var mob_attacking: Variant = body.get("_is_attacking")
if mob_attacking != null and mob_attacking == false:
    return
```

- Slimes have no `_is_attacking` → `body.get()` returns null → damage fires always (backward compatible).
- New mobs: null means never returned; false = not attacking, no damage; true = damage fires.

This lets each mob control its own damage window precisely without any central coordination.

---

## Player Combat Fixes

### Sprite stuck in idle after being hit
**Root cause:** `_start_attack()` did not check `_is_hurt`. Pressing attack during the hurt animation interrupted it before `animation_finished` could fire, leaving `_is_hurt = true` permanently. With `_is_hurt` stuck true, `_update_animation` was blocked from running indefinitely.

**Fix:** Added `not _is_hurt` to the attack guard in `_process`. The player cannot attack while the hurt animation is playing; this also naturally prevents the stuck state.

### B button triggering dodge when closing menus
**Root cause:** `teleport_menu.gd` (and similar menus) pause the tree and close via `_unhandled_input` with `set_input_as_handled()`. However, `player.gd` checks dodge via `Input.is_action_just_pressed()` (polling), which ignores `set_input_as_handled`. On the first unpaused frame the just-pressed state from the B press was still visible.

**Fix:** `player.gd` overrides `_notification(NOTIFICATION_UNPAUSED)` to set `_post_unpause_grace = 0.15`. The dodge check is gated behind `_post_unpause_grace <= 0.0`, blocking dodge input for 150 ms after any unpause event.

## Why Mobs Must Not Set `linear_velocity` While Hurt

`apply_central_impulse` changes a RigidBody2D's velocity in the physics step. On the very next `_physics_process` call, the chase AI was reassigning `linear_velocity = _direction_to_player_with_noise(...)`, which replaced the impulse velocity with forward movement, making knockback invisible. The fix: check `_is_hurt` and return before the velocity assignment.

---

## What to Avoid

| Anti-pattern | Problem |
|---|---|
| Setting mob `collision_mask` to include player (2) or entity (8) layers | Mobs generate physics forces against whatever they detect on their mask; including player/mob layers causes continuous pushing |
| Leaving `collision_mask = 1` on flying mobs (vampires) | Flying mobs get stuck on world geometry (crystals, rocks). Vampires use `collision_mask = 0` and enforce their own boundaries in `_integrate_forces`. |
| Player `collision_mask` not including layer 8 | Player passes through mob and NPC bodies; oscillation occurs as mob AI reacts to player inside its contact zone |
| Player-separation code inside `_integrate_forces` on mobs | Keeps mob permanently away from player; `HurtArea.body_entered` never fires; mob deals no damage |
| Setting `linear_velocity` every frame without an `_is_hurt` guard | Overrides `apply_central_impulse` knockback in the same frame it's applied; knockback appears to do nothing |
| Changing only mob `collision_mask` (without moving mob to a new layer) | Player's CharacterBody2D uses *its own* mask, not the mob's. Player mask=1 still detects mob layer=1 regardless of mob mask |
| Adding mob layer (8) back to player `collision_mask` | `move_and_slide()` recovery pushes the player out of ANY overlapping shape on its mask every frame — even stationary mobs will shove the player continuously |
| Moving StaticBody2D in player's collision mask | Godot 4 computes apparent velocity from transform delta on static bodies; CharacterBody2D `move_and_slide()` uses it to push the player — this is why wandering NPCs have no physics body |

---

## Adding a New Enemy Type

1. Extend `mob_base.gd` (inherits layer=8, mask=0, `take_damage`, `died` signal automatically).
2. Set `max_health`, `damage`, `knockback_force`, `aggro_radius` in `_ready()` before calling `super._ready()`.
3. In `_physics_process`, guard the velocity-setting block with `if _is_hurt: return`.
4. Use `contact_radius` (inherited from `mob_base`, auto-computed as `body_radius + 20.0` in `_ready()`) to stop chasing when within range — do not add a local constant.
5. Do **not** add player-separation logic to `_integrate_forces` — it prevents damage contact.
6. If the mob should only deal damage during a specific animation, declare `var _is_attacking: bool = false` and set it true/false around the attack window. The `_on_body_entered` gate in `player.gd` reads this automatically. Slimes (no `_is_attacking`) retain always-on contact damage — the gate is backward compatible.
7. Register the new scene in `field.gd` as a `@export var` and wire it in the editor.
