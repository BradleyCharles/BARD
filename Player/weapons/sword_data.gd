class_name SwordData

const ID        : String = "sword"
const DAMAGE    : int    = 1
const SWING_FPS : float  = 40.0
const KNOCKBACK : float  = 200.0
# Vector2 cannot be a GDScript const — static var is required for object types
static var hitbox: Vector2 = Vector2(40.0, 20.0)
