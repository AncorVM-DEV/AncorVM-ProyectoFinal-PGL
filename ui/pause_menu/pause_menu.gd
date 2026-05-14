extends CanvasLayer

@onready var resume_button = $ColorRect/CenterContainer/VBoxContainer/ResumeButton
@onready var menu_button = $ColorRect/CenterContainer/VBoxContainer/MenuButton

func _ready():
	# PROCESS_MODE_ALWAYS hace que este nodo procese SIEMPRE:
	# tanto cuando el juego corre (para poder abrir la pausa)
	# como cuando el árbol está pausado (para poder cerrarla)
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	resume_button.pressed.connect(_on_resume_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _process(_delta):
	# Acción "pause" en el Input Map (Escape)
	if Input.is_action_just_pressed("pause"):
		if get_tree().paused:
			resume()
		else:
			pause()

func pause():
	show()
	# Pausamos el árbol entero: el jugador y los enemigos se congelan
	# pero siguen siendo visibles detrás del ColorRect semitransparente
	get_tree().paused = true

func resume():
	hide()
	get_tree().paused = false

func _on_resume_pressed():
	resume()

func _on_menu_pressed():
	# Desactivamos la pausa ANTES de cambiar de escena
	# Si no, el árbol llegaría al menú principal todavía pausado
	get_tree().paused = false
	GameManager.reset_run()
	get_tree().change_scene_to_file("res://ui/main_menu/MainMenu.tscn")
