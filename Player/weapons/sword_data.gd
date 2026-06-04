class_name SwordData

const ID        : String = "sword"
const DAMAGE    : int    = 1
const SWING_FPS : float  = 40.0
const KNOCKBACK : float  = 300.0
# Vector2 cannot be a GDScript const — static var is required for object types
static var hitbox:  Vector2 = Vector2(50.0, 50.0)
const SPRITE_OFFSET : float  = 24.0
