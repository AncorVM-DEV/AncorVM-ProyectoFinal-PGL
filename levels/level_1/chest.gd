extends Node2D

@onready var interaction_label = $Label
@onready var area = $Area2D
@onready var anim = $AnimationPlayer

var is_player_nearby = false
var is_opened = false

func _ready():
	interaction_label.visible = false
	# Conectamos las señales de la Area2D para detectar al jugador
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if is_opened:
		return # Si ya esta abierto no hace nada
	if body.name == "Player":
		is_player_nearby = true
		interaction_label.visible = true

func _on_body_exited(body):
	if body.name == "Player":
		is_player_nearby = false
		interaction_label.visible = false

func _process(_delta):
	# Verificamos que la acción "interactuar" esté en el Mapa de Entradas
	if is_player_nearby and Input.is_action_just_pressed("interactuar"):
		open_chest()

func open_chest():
	is_opened = true
	is_player_nearby = false
	interaction_label.visible = false
	# Animacion de cofre abierto
	anim.play("open")
	# TODO: Reproducir sonido
	GameManager.unlock_ability("roll")
	print("¡Cofre abierto! Conseguiste: Roll")
	# Desactivamos el script para que no se pueda abrir dos veces
	area.monitoring = false
	set_process(false)
