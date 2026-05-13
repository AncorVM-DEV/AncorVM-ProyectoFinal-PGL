extends Node2D

# --- VARIABLES CONFIGURABLES ---
# Ruta de la escena del siguiente nivel. Se asigna desde el inspector arrastrando el .tscn de Level_2.
# @export_file con filtro "*.tscn" me obliga a elegir solo archivos de escena, evitando errores tontos.
@export_file("*.tscn") var next_level_path: String = ""

# Referencias a nuestros nodos (con @onready se cargan al empezar el juego)
@onready var label = $Label     # El cartel de "Pulsa E para entrar" que aparece al acercarse
@onready var area = $Area2D     # La zona de detección que detecta cuando el jugador está cerca

# --- VARIABLES DE MEMORIA ---
var is_player_nearby = false    # Recuerda si el jugador está dentro de la zona de la puerta

func _ready():
	# El label empieza oculto, solo se mostrará cuando el jugador esté cerca
	label.visible = false
	# Conectamos las señales de la Area2D para detectar al jugador
	# body_entered se dispara cuando algo entra en la zona, body_exited cuando algo sale
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

# Se llama automáticamente cuando un cuerpo (un CharacterBody2D, etc.) entra en la Area2D
func _on_body_entered(body):
	# Comprobamos si el cuerpo que ha entrado es el jugador (uso grupos en vez de body.name para que sea más robusto)
	if body.is_in_group("player"):
		is_player_nearby = true
		label.visible = true    # Mostramos el cartel de "Pulsa E"

# Se llama automáticamente cuando un cuerpo sale de la Area2D
func _on_body_exited(body):
	if body.is_in_group("player"):
		is_player_nearby = false
		label.visible = false   # Ocultamos el cartel al alejarnos

func _process(_delta):
	# Verificamos que la acción "interactuar" esté en el Mapa de Entradas (la tecla E)
	# Solo cambiamos de nivel si el jugador está cerca Y pulsa la E
	if is_player_nearby and Input.is_action_just_pressed("interactuar"):
		change_level()

# Función que se encarga de cambiar a la siguiente escena
func change_level():
	# Si se me ha olvidado asignar el nivel en el inspector, aviso por consola y no hago nada
	# Así evito que el juego crashee si la puerta está mal configurada
	if next_level_path == "":
		print("Puerta sin nivel asignado")
		return
	# Guardamos en el GameManager la ruta del nuevo nivel para que el respawn funcione bien si morimos allí
	GameManager.current_level_path = next_level_path
	# Cambiamos a la escena del siguiente nivel
	get_tree().change_scene_to_file(next_level_path)
