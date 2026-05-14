extends CanvasLayer

@onready var resume_button = $ColorRect/CenterContainer/VBoxContainer/ResumeButton
@onready var menu_button = $ColorRect/CenterContainer/VBoxContainer/MenuButton

func _ready():
	# Este nodo tiene que seguir procesando input AUNQUE el árbol esté pausado
	# Si no lo ponemos, al pausar el juego este menú también se pararía y no podríamos cerrarlo
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	# Empezamos oculto, solo se muestra al pulsar Escape
	hide()
	resume_button.pressed.connect(_on_resume_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _process(_delta):
	# Escuchamos la tecla Escape en cada frame para abrir/cerrar la pausa
	# Acción "pause" en el Input Map (Tecla Escape)
	if Input.is_action_just_pressed("pause"):
		if get_tree().paused:
			resume()
		else:
			pause()

func pause():
	show()
	# Pausamos el árbol de escena completo: el jugador, enemigos, etc. se quedan congelados
	# pero siguen siendo visibles detrás del menú (el ColorRect semitransparente da el efecto oscurecido)
	get_tree().paused = true

func resume():
	hide()
	get_tree().paused = false

func _on_resume_pressed():
	resume()

func _on_menu_pressed():
	# Importante: desactivamos la pausa ANTES de cambiar de escena
	# Si no lo hacemos, el árbol seguiría pausado al cargar el menú
	get_tree().paused = false
	GameManager.reset_run()
	get_tree().change_scene_to_file("res://ui/main_menu/MainMenu.tscn")
