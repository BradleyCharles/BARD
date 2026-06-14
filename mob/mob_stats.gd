class_name MobStats

# ── SLIMES — zone_c ───────────────────────────────────────────────────────────

# Slime1 · Pack Mentality · flees alone, chases on pack
const SLIME1_MAX_HEALTH          : int   = 3
const SLIME1_DAMAGE              : int   = 1
const SLIME1_KNOCKBACK           : float = 150.0
const SLIME1_AGGRO_RADIUS        : float = 200.0
const SLIME1_HITBOX_RADIUS       : float = 10.0
const SLIME1_SPEED_MIN           : float = 40.0
const SLIME1_SPEED_MAX           : float = 70.0
const SLIME1_PACK_TRIGGER_RADIUS : float = 200.0
const SLIME1_PACK_COUNT_NEEDED   : int   = 2
const SLIME1_LINK_SCAN_INTERVAL  : float = 0.5

# Slime2 · Pack Mentality · passive until hit, then alerts nearby pack
const SLIME2_MAX_HEALTH          : int   = 6
const SLIME2_DAMAGE              : int   = 2
const SLIME2_KNOCKBACK           : float = 250.0
const SLIME2_AGGRO_RADIUS        : float = 200.0
const SLIME2_HITBOX_RADIUS       : float = 10.0
const SLIME2_SPEED_MIN           : float = 50.0
const SLIME2_SPEED_MAX           : float = 100.0
const SLIME2_ALERT_RADIUS        : float = 200.0

# Slime3 · Weak Aggressive · chases on sight
const SLIME3_MAX_HEALTH          : int   = 8
const SLIME3_DAMAGE              : int   = 3
const SLIME3_KNOCKBACK           : float = 350.0
const SLIME3_AGGRO_RADIUS        : float = 200.0
const SLIME3_HITBOX_RADIUS       : float = 10.0
const SLIME3_SPEED_MIN           : float = 60.0
const SLIME3_SPEED_MAX           : float = 110.0

# ── ORCS — zone_a ─────────────────────────────────────────────────────────────

# Orc1 · Charger AI
const ORC1_MAX_HEALTH            : int   = 8
const ORC1_DAMAGE                : int   = 2
const ORC1_KNOCKBACK             : float = 150.0
const ORC1_AGGRO_RADIUS          : float = 200.0
const ORC1_HITBOX_RADIUS         : float = 18.0
const ORC1_WANDER_SPEED          : float = 40.0
const ORC1_CHARGE_SPEED          : float = 280.0
const ORC1_CHARGE_DURATION       : float = 1.2
const ORC1_CHARGE_TRIGGER_RADIUS : float = 100.0
const ORC1_RECOVER_DURATION      : float = 0.8

# Orc2 · Charger AI
const ORC2_MAX_HEALTH            : int   = 14
const ORC2_DAMAGE                : int   = 3
const ORC2_KNOCKBACK             : float = 250.0
const ORC2_AGGRO_RADIUS          : float = 200.0
const ORC2_HITBOX_RADIUS         : float = 20.0
const ORC2_WANDER_SPEED          : float = 45.0
const ORC2_CHARGE_SPEED          : float = 320.0
const ORC2_CHARGE_DURATION       : float = 1.2
const ORC2_CHARGE_TRIGGER_RADIUS : float = 100.0
const ORC2_RECOVER_DURATION      : float = 0.8

# Orc3 · Charger AI
const ORC3_MAX_HEALTH            : int   = 22
const ORC3_DAMAGE                : int   = 4
const ORC3_KNOCKBACK             : float = 350.0
const ORC3_AGGRO_RADIUS          : float = 200.0
const ORC3_HITBOX_RADIUS         : float = 22.0
const ORC3_WANDER_SPEED          : float = 50.0
const ORC3_CHARGE_SPEED          : float = 360.0
const ORC3_CHARGE_DURATION       : float = 1.2
const ORC3_CHARGE_TRIGGER_RADIUS : float = 100.0
const ORC3_RECOVER_DURATION      : float = 0.8

# ── PLANTS — zone_a ───────────────────────────────────────────────────────────

# Plant1 · Creeper AI
const PLANT1_MAX_HEALTH          : int   = 10
const PLANT1_DAMAGE              : int   = 2
const PLANT1_KNOCKBACK           : float = 200.0
const PLANT1_AGGRO_RADIUS        : float = 200.0
const PLANT1_HITBOX_RADIUS       : float = 16.0
const PLANT1_WANDER_SPEED        : float = 10.0
const PLANT1_AGGRO_SPEED         : float = 25.0
const PLANT1_STRIKE_RADIUS       : float = 90.0

# Plant2 · Creeper AI
const PLANT2_MAX_HEALTH          : int   = 18
const PLANT2_DAMAGE              : int   = 3
const PLANT2_KNOCKBACK           : float = 300.0
const PLANT2_AGGRO_RADIUS        : float = 200.0
const PLANT2_HITBOX_RADIUS       : float = 18.0
const PLANT2_WANDER_SPEED        : float = 12.0
const PLANT2_AGGRO_SPEED         : float = 30.0
const PLANT2_STRIKE_RADIUS       : float = 90.0

# Plant3 · Creeper AI
const PLANT3_MAX_HEALTH          : int   = 28
const PLANT3_DAMAGE              : int   = 5
const PLANT3_KNOCKBACK           : float = 400.0
const PLANT3_AGGRO_RADIUS        : float = 200.0
const PLANT3_HITBOX_RADIUS       : float = 20.0
const PLANT3_WANDER_SPEED        : float = 15.0
const PLANT3_AGGRO_SPEED         : float = 35.0
const PLANT3_STRIKE_RADIUS       : float = 90.0

# ── VAMPIRES — zone_b ─────────────────────────────────────────────────────────

# Vampire1 · Stalker AI · orbit + timed dash
const VAMPIRE1_MAX_HEALTH        : int   = 6
const VAMPIRE1_DAMAGE            : int   = 1
const VAMPIRE1_KNOCKBACK         : float = 200.0
const VAMPIRE1_AGGRO_RADIUS      : float = 200.0
const VAMPIRE1_HITBOX_RADIUS     : float = 14.0
const VAMPIRE1_ORBIT_RADIUS      : float = 200.0
const VAMPIRE1_ORBIT_SPEED       : float = 90.0
const VAMPIRE1_DASH_SPEED        : float = 350.0
const VAMPIRE1_DASH_DURATION     : float = 0.4
const VAMPIRE1_RECOVER_DURATION  : float = 0.6
const VAMPIRE1_DASH_INTERVAL_MIN : float = 3.0
const VAMPIRE1_DASH_INTERVAL_MAX : float = 5.0

# Vampire2 · Stalker AI · orbit + timed dash
const VAMPIRE2_MAX_HEALTH        : int   = 10
const VAMPIRE2_DAMAGE            : int   = 2
const VAMPIRE2_KNOCKBACK         : float = 300.0
const VAMPIRE2_AGGRO_RADIUS      : float = 200.0
const VAMPIRE2_HITBOX_RADIUS     : float = 16.0
const VAMPIRE2_ORBIT_RADIUS      : float = 200.0
const VAMPIRE2_ORBIT_SPEED       : float = 100.0
const VAMPIRE2_DASH_SPEED        : float = 400.0
const VAMPIRE2_DASH_DURATION     : float = 0.4
const VAMPIRE2_RECOVER_DURATION  : float = 0.6
const VAMPIRE2_DASH_INTERVAL_MIN : float = 2.5
const VAMPIRE2_DASH_INTERVAL_MAX : float = 4.0

# Vampire3 · Stalker AI · orbit + timed dash
const VAMPIRE3_MAX_HEALTH        : int   = 16
const VAMPIRE3_DAMAGE            : int   = 3
const VAMPIRE3_KNOCKBACK         : float = 400.0
const VAMPIRE3_AGGRO_RADIUS      : float = 200.0
const VAMPIRE3_HITBOX_RADIUS     : float = 18.0
const VAMPIRE3_ORBIT_RADIUS      : float = 200.0
const VAMPIRE3_ORBIT_SPEED       : float = 110.0
const VAMPIRE3_DASH_SPEED        : float = 450.0
const VAMPIRE3_DASH_DURATION     : float = 0.4
const VAMPIRE3_RECOVER_DURATION  : float = 0.6
const VAMPIRE3_DASH_INTERVAL_MIN : float = 2.0
const VAMPIRE3_DASH_INTERVAL_MAX : float = 3.5

# ── BOSSES ────────────────────────────────────────────────────────────────────

# Slime3 Boss · AOE pulse · spawns after 10 combined slime kills · drops 20 Goop
const SLIME3_BOSS_MAX_HEALTH         : int   = 30
const SLIME3_BOSS_DAMAGE             : int   = 5
const SLIME3_BOSS_KNOCKBACK          : float = 600.0
const SLIME3_BOSS_HITBOX_RADIUS      : float = 30.0
const SLIME3_BOSS_SPEED              : float = 60.0
const SLIME3_BOSS_AOE_DAMAGE         : int   = 7
const SLIME3_BOSS_AOE_KNOCKBACK      : float = 700.0
const SLIME3_BOSS_AOE_RADIUS         : float = 150.0
const SLIME3_BOSS_ATTACK_COOLDOWN    : float = 5.0
const SLIME3_BOSS_TELEGRAPH_DURATION : float = 1.5
const SLIME3_BOSS_GOOP_DROP          : int   = 20

# Orc3 Boss · Telegraphed charge · spawns after 10 combined orc kills · drops 15 Goop
const ORC3_BOSS_MAX_HEALTH           : int   = 60
const ORC3_BOSS_DAMAGE               : int   = 6
const ORC3_BOSS_KNOCKBACK            : float = 600.0
const ORC3_BOSS_HITBOX_RADIUS        : float = 22.0
const ORC3_BOSS_SPEED                : float = 70.0
const ORC3_BOSS_CHARGE_SPEED         : float = 500.0
const ORC3_BOSS_CHARGE_DURATION      : float = 1.0
const ORC3_BOSS_CHARGE_TRIGGER_RADIUS: float = 350.0
const ORC3_BOSS_TELEGRAPH_DURATION   : float = 1.5
const ORC3_BOSS_ATTACK_COOLDOWN      : float = 5.0
const ORC3_BOSS_RECOVER_DURATION     : float = 1.0
const ORC3_BOSS_GOOP_DROP            : int   = 15

# Plant3 Boss · Starburst AOE beams · spawns after 10 combined plant kills · drops 15 Goop
const PLANT3_BOSS_MAX_HEALTH          : int   = 50
const PLANT3_BOSS_DAMAGE              : int   = 7
const PLANT3_BOSS_KNOCKBACK           : float = 500.0
const PLANT3_BOSS_HITBOX_RADIUS       : float = 30.0
const PLANT3_BOSS_CREEP_SPEED         : float = 30.0
const PLANT3_BOSS_AOE_DAMAGE          : int   = 7
const PLANT3_BOSS_AOE_KNOCKBACK       : float = 500.0
const PLANT3_BOSS_BEAM_REACH          : float = 400.0
const PLANT3_BOSS_BEAM_HALF_WIDTH     : float = 50.0
const PLANT3_BOSS_BEAM_HALF_WIDTH_RAD : float = 0.35
const PLANT3_BOSS_ATTACK_TRIGGER_RADIUS: float = 400.0
const PLANT3_BOSS_ATTACK_COOLDOWN     : float = 6.0
const PLANT3_BOSS_TELEGRAPH_DURATION  : float = 2.0
const PLANT3_BOSS_GOOP_DROP           : int   = 15

# Vampire3 Boss · Orbit + life-drain dash · spawns after 20 combined vampire kills · drops 15 Goop
const VAMPIRE3_BOSS_MAX_HEALTH        : int   = 40
const VAMPIRE3_BOSS_DAMAGE            : int   = 5
const VAMPIRE3_BOSS_KNOCKBACK         : float = 400.0
const VAMPIRE3_BOSS_HITBOX_RADIUS     : float = 30.0
const VAMPIRE3_BOSS_ORBIT_RADIUS      : float = 200.0
const VAMPIRE3_BOSS_ORBIT_SPEED       : float = 130.0
const VAMPIRE3_BOSS_DASH_SPEED        : float = 500.0
const VAMPIRE3_BOSS_DASH_DURATION     : float = 0.35
const VAMPIRE3_BOSS_RECOVER_DURATION  : float = 0.6
const VAMPIRE3_BOSS_DASH_INTERVAL_MIN : float = 2.0
const VAMPIRE3_BOSS_DASH_INTERVAL_MAX : float = 3.5
const VAMPIRE3_BOSS_DRAIN_HEAL        : int   = 4
const VAMPIRE3_BOSS_GOOP_DROP         : int   = 15
