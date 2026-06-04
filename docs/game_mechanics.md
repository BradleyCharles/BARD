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
| `collision_mask` | **0** | Detects nothing — generates zero physics constraint forces; cannot push player or other mobs |

Set unconditionally in `mob_base._ready()`, inherited by all mob subclasses (slime1, slime2, slime3, elite, boss variants).

**Key rule:** `collision_mask = 0` is what prevents mobs from pushing. Even though the player's CharacterBody2D detects mob bodies (player mask 9 ⊃ layer 8), the physics engine only applies mutual constraint forces when **both** bodies detect each other. Mob mask = 0 breaks that mutuality — mobs are solid walls to the player but exert no force.

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

| Weapon | DAMAGE | KNOCKBACK | SWING_FPS | Hitbox |
|--------|--------|-----------|-----------|--------|
| Sword | 1 | 200.0 | 40.0 | 40×20 px |
| Axe | 2 | 400.0 | 24.0 | 16×28 px |

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

### Iframe Pause

All slimes call `_player_is_invincible()` (defined in `mob_base.gd`) before resuming chase. While the player has active iframes the mob holds position — it pauses at contact distance after landing a hit and only resumes when iframes expire.

---

## Why Mobs Must Not Set `linear_velocity` While Hurt

`apply_central_impulse` changes a RigidBody2D's velocity in the physics step. On the very next `_physics_process` call, the chase AI was reassigning `linear_velocity = _direction_to_player_with_noise(...)`, which replaced the impulse velocity with forward movement, making knockback invisible. The fix: check `_is_hurt` and return before the velocity assignment.

---

## What to Avoid

| Anti-pattern | Problem |
|---|---|
| Setting mob `collision_mask` to detect player or other mobs | Mobs generate physics forces against whatever they detect; with `mask ≠ 0` they push the player and each other |
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
4. Add a `CONTACT_RADIUS` constant and stop chasing when within it.
5. Do **not** add player-separation logic to `_integrate_forces` — it prevents damage contact.
6. Register the new scene in `field.gd` as a `@export var` and wire it in the editor.
