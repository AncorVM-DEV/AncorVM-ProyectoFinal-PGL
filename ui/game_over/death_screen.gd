extends Control

# Igual que el menú principal, esta pantalla es un nodo Control porque es UI pura
# (botones, texto, sin elementos del mundo del juego)

# Referencias a nuestros nodos (con @onready se cargan al empezar el juego)
@onready var retry_button = $CenterContainer/VBoxContainer/RetryButton    # Botón "Reintentar"
@onready var menu_button = $CenterContainer/VBoxContainer/MenuButton      # Botón "Volver al menú"

func _ready():
	# Conectamos la señal "pressed" de cada botón a su función correspondiente
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

# Se llama cuando se pulsa el botón "Reintentar"
func _on_retry_pressed():
	# Reseteamos las vidas a 3 (pero MANTENEMOS las habilidades desbloqueadas como el Roll)
	# Así si el jugador ya consiguió el roll antes de morir, no tiene que volver a buscar el cofre
	GameManager.reset_run()
	# Volvemos a cargar el nivel donde estaba el jugador cuando murió
	# El GameManager guarda esta ruta cada vez que cruzamos una puerta
	get_tree().change_scene_to_file(GameManager.current_level_path)

# Se llama cuando se pulsa el botón "Volver al menú"
func _on_menu_pressed():
	# Reseteamos las vidas (las habilidades se reseteán en el botón "Empezar" del menú)
	GameManager.reset_run()
	# Cargamos el menú principal
	get_tree().change_scene_to_file("res://ui/main_menu/MainMenu.tscn")
