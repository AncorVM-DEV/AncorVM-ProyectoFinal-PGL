extends Control

# Este script va en un nodo Control (no Node2D ni CanvasLayer).
# Control es el nodo base para toda la UI en Godot: botones, labels, contenedores...
# Tiene un sistema de anclajes y márgenes pensado para adaptarse a distintas resoluciones de pantalla.

# Referencias a nuestros nodos (con @onready se cargan al empezar el juego)
@onready var start_button = $ColorRect/CenterContainer/VBoxContainer/StartButton    # Botón "Empezar"
@onready var quit_button = $ColorRect/CenterContainer/VBoxContainer/QuitButton      # Botón "Salir"

func _ready():
	# Conectamos la señal "pressed" de cada botón a su función correspondiente
	# Esta señal la emite Godot automáticamente cuando el jugador hace clic en el botón
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

# Se llama cuando se pulsa el botón "Empezar"
func _on_start_pressed():
	# Reseteamos las vidas a 3 por si veníamos de una partida anterior
	GameManager.reset_run()
	# Reset completo al empezar partida nueva: quitamos el roll para que haya que volver a conseguirlo
	# (si no, una vez abierto el cofre lo tendríamos para siempre aunque empezáramos partida nueva)
	GameManager.has_roll = false
	# Cargamos la escena del primer nivel
	get_tree().change_scene_to_file("res://levels/level_1/Level_1.tscn")

# Se llama cuando se pulsa el botón "Salir"
func _on_quit_pressed():
	# Cierra el juego completamente
	get_tree().quit()
