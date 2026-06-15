class_name AxeData

const ID             : String = "axe"
const DAMAGE         : int    = 6
const SWING_FPS      : float  = 15.0
const KNOCKBACK      : float  = 200.0
const SPRITE_PATH    : String = "res://assets/Axe/"
const FRAME_COUNT    : int    = 10
const NATIVE_SIZE    : float  = 496.0
const HITBOX_OFFSET  : float  = 45.0
const HIT_FRAME_START: int    = 2
const HIT_FRAME_END  : int    = 7
const MOVE_MODIFIER  : float  = 0.0   # 0 % speed while swinging (full stop)
const HITSTOP        : float  = 0.12  # seconds Engine.time_scale = 0 on hit
const SHAKE_INTENSITY: float  = 4.0
const SHAKE_DURATION : float  = 0.22
const SHAKE_FREQUENCY: float  = 80.0

# Vector2 cannot be a GDScript const — static var is required for object types
static var hitbox      : Vector2 = Vector2(35, 70.0)  # Width x Height (collision)
static var sprite_size : Vector2 = Vector2(75.0, 50.0)  # Width x Height (animation)
static var sfx_paths   : Array[String] = [
	"res://assets/SFX/axe1.wav",
	"res://assets/SFX/axe2.wav",
	"res://assets/SFX/axe3.wav",
	"res://assets/SFX/axe4.wav",
]
