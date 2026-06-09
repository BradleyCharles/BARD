class_name SwordData

const ID             : String = "sword"
const DAMAGE         : int    = 1
const SWING_FPS      : float  = 40.0
const KNOCKBACK      : float  = 300.0
const SPRITE_PATH    : String = "res://assets/Sword/"
const FRAME_COUNT    : int    = 8
const NATIVE_SIZE    : float  = 496.0
const SPRITE_OFFSET  : float  = 0.0
const HIT_FRAME_START: int    = 2
const HIT_FRAME_END  : int    = 6

# Vector2 cannot be a GDScript const — static var is required for object types
static var hitbox: Vector2 = Vector2(100.0, 50.0) # Width x Length
