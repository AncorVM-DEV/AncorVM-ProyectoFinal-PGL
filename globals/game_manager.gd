extends Node

# --- ESTADO PERSISTENTE ENTRE ESCENAS ---
const MAX_LIVES := 3
var lives: int = MAX_LIVES
var has_roll: bool = false

# Punto de respawn (se actualiza en cada nivel)
var respawn_position: Vector2 = Vector2.ZERO
var current_level_path: String = "res://levels/level_1/Level_1.tscn"

# --- SEÑALES ---
signal lives_changed(new_lives: int)
signal player_died
signal ability_unlocked(ability_name: String)

func take_damage() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		player_died.emit()

func reset_run() -> void:
	# Reinicia partida pero MANTIENE las habilidades desbloqueadas
	# Si quiero llegar a poner que al morir se pierda el Roll, pongo has_roll = false aquí
	lives = MAX_LIVES
	lives_changed.emit(lives)

func unlock_ability(ability: String) -> void:
	if ability == "roll":
		has_roll = true
	ability_unlocked.emit(ability)
