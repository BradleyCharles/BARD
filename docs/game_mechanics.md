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
| Player (root) | CharacterBody2D | 2 | **9** (1+8) | Blocked by world (layer 1) and entity bodies (layer 8); set in `_ready()` |
| SwordHitbox | Area2D | 0 | **8** | Detects mob bodies on layer 8; `body_entered` → `_on_sword_hit` |
| HurtArea | Area2D | 2 | **8** | Detects mob bodies on layer 8; `body_entered` → `_on_body_entered` |

`collision_mask = 9` and both Area2D masks are set **in code** inside `player.gd:_ready()`, overriding the `.tscn` defaults. Do not change the `.tscn` values — they are overridden at runtime.

### Mobs — `mob/mob_base.gd`

| Property | Value | Reason |
|----------|-------|--------|
| `collision_layer` | **8** | Visible on entity layer; detectable by player's HurtArea and SwordHitbox |
| `collision_mask` | **0** | Detects nothing — generates zero physics constraint forces; cannot push player or other mobs |

Set unconditionally in `mob_base._ready()`, inherited by all mob subclasses (slime1, slime2, slime3, elite, boss variants).

**Key rule:** `collision_mask = 0` is what prevents mobs from pushing. Even though the player's CharacterBody2D detects mob bodies (player mask 9 ⊃ layer 8), the physics engine only applies mutual constraint forces when **both** bodies detect each other. Mob mask = 0 breaks that mutuality — mobs are solid walls to the player but exert no force.

### NPCs — `npc/npc_base.gd` (`_add_physics_body()`)

Each NPC (Node2D root) gets a `StaticBody2D` child added programmatically in `_ready()`:

| Property | Value | Reason |
|----------|-------|--------|
| `collision_layer` | **8** | Same entity layer as mobs — player's mask 9 is blocked by it |
| `collision_mask` | **0** | StaticBody2D is immovable by definition; mask 0 prevents any force feedback |
| Shape | `CircleShape2D`, radius 12 | Approximate NPC footprint |

`StaticBody2D` nodes do not apply impulses when they move. When a wandering NPC walks into the player's space, no push occurs — the overlap resolves passively on the player's next `move_and_slide()` call. The player can walk into an NPC and be stopped; NPCs do not launch the player.

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

### Contact Radius (tuning knob)

`CONTACT_RADIUS: float = 44.0` is defined as a constant in both `slime1.gd` and `slime3.gd`. Adjust this value to control how close mobs stop to the player before halting their chase. At 44 px, the mob's collision shape edge is approximately touching the player's collision shape edge.

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
| NPC StaticBody2D on layer 1 | Player mask=1 detects it; when NPC wanders into player, moving StaticBody2D resolves the overlap by pushing the player |

---

## Adding a New Enemy Type

1. Extend `mob_base.gd` (inherits layer=8, mask=0, `take_damage`, `died` signal automatically).
2. Set `max_health`, `damage`, `knockback_force`, `aggro_radius` in `_ready()` before calling `super._ready()`.
3. In `_physics_process`, guard the velocity-setting block with `if _is_hurt: return`.
4. Add a `CONTACT_RADIUS` constant and stop chasing when within it.
5. Do **not** add player-separation logic to `_integrate_forces` — it prevents damage contact.
6. Register the new scene in `field.gd` as a `@export var` and wire it in the editor.
