extends CanvasLayer

@onready var menu_button = $ColorRect/CenterContainer/VBoxContainer/MenuButton

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()
	# Escuchamos la señal de victoria del GameManager (se emite al recoger las 7 llaves)
	GameManager.game_won.connect(_on_game_won)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_game_won():
	# Pequeña pausa antes de mostrar el menú de victoria
	await get_tree().create_timer(0.5).timeout
	show()
	get_tree().paused = true

func _on_menu_pressed():
	get_tree().paused = false
	GameManager.reset_run()
	GameManager.has_roll = false
	get_tree().change_scene_to_file("res://ui/main_menu/MainMenu.tscn")
