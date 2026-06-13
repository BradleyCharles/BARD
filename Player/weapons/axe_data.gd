class_name AxeData

const ID             : String = "axe"
const DAMAGE         : int    = 2
const SWING_FPS      : float  = 15.0
const KNOCKBACK      : float  = 600.0
const SPRITE_PATH    : String = "res://assets/Axe/"
const FRAME_COUNT    : int    = 10
const NATIVE_SIZE    : float  = 496.0
const HITBOX_OFFSET  : float  = 45.0
const HIT_FRAME_START: int    = 2
const HIT_FRAME_END  : int    = 7

# Vector2 cannot be a GDScript const — static var is required for object types
static var hitbox      : Vector2 = Vector2(35, 70.0)  # Width x Height (collision)
static var sprite_size : Vector2 = Vector2(75.0, 50.0)  # Width x Height (animation)
