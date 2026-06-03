class_name AxeData

const ID        : String = "axe"
const DAMAGE    : int    = 2
const SWING_FPS : float  = 24.0
const KNOCKBACK : float  = 600.0
# Vector2 cannot be a GDScript const — static var is required for object types
static var hitbox: Vector2 = Vector2(42.0, 38.0)
