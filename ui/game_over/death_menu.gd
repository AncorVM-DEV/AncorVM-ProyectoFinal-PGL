extends CanvasLayer

@onready var retry_button = $ColorRect/CenterContainer/VBoxContainer/RetryButton
@onready var menu_button = $ColorRect/CenterContainer/VBoxContainer/MenuButton

func _ready():
	# Igual que el menú de pausa, necesita procesar aunque el árbol esté pausado
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()
	# Escuchamos la señal del GameManager: cuando el jugador se quede sin vidas, nos mostramos
	GameManager.player_died.connect(_on_player_died)
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_player_died():
	# Esperamos un momento para que se vea la animación de muerte antes de mostrar el menú
	await get_tree().create_timer(1.0).timeout
	show()
	# Pausamos el juego: el player queda visible y congelado detrás del ColorRect oscuro
	get_tree().paused = true

func _on_retry_pressed():
	get_tree().paused = false
	GameManager.reset_run()
	# Recargamos el nivel donde estaba el jugador cuando murió
	get_tree().change_scene_to_file(GameManager.current_level_path)

func _on_menu_pressed():
	get_tree().paused = false
	GameManager.reset_run()
	get_tree().change_scene_to_file("res://ui/main_menu/MainMenu.tscn")
