extends "res://mob/slime1.gd"

func _ready() -> void:
	max_health      = 6
	aggro_radius    = 200.0
	knockback_force = 350.0
	super._ready()
	set_meta("monster_type", "slime1_elite")
	modulate = Color(0.7, 0.5, 1.0, 1.0)


func _reset_modulate() -> void:
	modulate = Color(0.7, 0.5, 1.0, 1.0)


func _on_died() -> void:
	if randf() < 0.1:
		SceneManager.earn_slime_goop(1)
	super._on_died()
