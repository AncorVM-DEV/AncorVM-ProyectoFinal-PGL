extends Node

# --- ESTADO PERSISTENTE ENTRE ESCENAS ---
const MAX_LIVES := 3
var lives: int = MAX_LIVES
var has_roll: bool = false

# --- LLAVES ---
const MAX_KEYS := 7          # Total de llaves que hay que recoger para ganar
var key_count: int = 0       # Cuántas llaves llevamos recogidas


# Punto de respawn (se actualiza en cada nivel)
var respawn_position: Vector2 = Vector2.ZERO
var current_level_path: String = "res://levels/level_1/Level_1.tscn"

# --- SEÑALES ---
signal lives_changed(new_lives: int)
signal player_died
signal ability_unlocked(ability_name: String)
signal key_collected(total_keys: int)   # Se emite cada vez que recogemos una llave
signal game_won                         # Se emite cuando recogemos las 7 llaves

func take_damage() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		player_died.emit()

func reset_run() -> void:
	# Reinicia vida y llave pero MANTIENE las habilidades desbloqueadas
	# Si quiero llegar a poner que al morir se pierda el Roll, pongo has_roll = false aquí
	lives = MAX_LIVES
	key_count = 0
	lives_changed.emit(lives)

func unlock_ability(ability: String) -> void:
	if ability == "roll":
		has_roll = true
	ability_unlocked.emit(ability)
	
func collect_key() -> void:
	key_count += 1
	key_collected.emit(key_count)
	# Si hemos recogido todas las llaves, emitimos la señal de victoria
	if key_count >= MAX_KEYS:
		game_won.emit()
