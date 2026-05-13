extends CanvasLayer

# Este script va en un CanvasLayer en vez de un Node2D normal.
# Un CanvasLayer hace que la UI se dibuje SIEMPRE encima del juego y se quede fija en la pantalla
# (no se mueve con la cámara). Perfecto para HUDs, menús, etc.

# Referencias a nuestros nodos (con @onready se cargan al empezar el juego)
@onready var lives_label = $MarginContainer/VBoxContainer/LivesLabel              # El label que muestra los corazones (♥ ♥ ♥)
@onready var roll_container = $MarginContainer/VBoxContainer/RollContainer        # El contenedor con la etiqueta "Roll:" y la barra de cooldown
@onready var roll_bar = $MarginContainer/VBoxContainer/RollContainer/RollBar      # La ProgressBar que indica si el roll está listo o en cooldown

func _ready():
	# Nos suscribimos a las señales del GameManager para reaccionar cuando cambian las vidas o se desbloquea una habilidad
	# Así el HUD se actualiza SOLO cuando hace falta, sin tener que comprobarlo cada frame
	GameManager.lives_changed.connect(update_lives)
	GameManager.ability_unlocked.connect(_on_ability_unlocked)
	
	# Inicializamos el HUD con el estado actual del GameManager
	# Esto es importante porque al cambiar de escena las señales ya se han emitido antes y nos las perderíamos
	update_lives(GameManager.lives)
	# El contenedor del roll solo se muestra si ya tenemos la habilidad desbloqueada
	# (al empezar el juego está oculto, aparece cuando abrimos el cofre)
	roll_container.visible = GameManager.has_roll

# Función que actualiza la visualización de las vidas (la llama la señal lives_changed)
func update_lives(lives: int):
	var hearts = ""
	# Por cada vida que nos quede, añadimos un corazón lleno
	for i in range(lives):
		hearts += "♥ "
	# Por cada vida perdida, añadimos un corazón vacío (así siempre se ven los 3 huecos)
	# Ejemplo con 2 vidas de 3: "♥ ♥ ♡"
	for i in range(GameManager.MAX_LIVES - lives):
		hearts += "♡ "
	# strip_edges() quita el espacio de más que queda al final del bucle
	lives_label.text = hearts.strip_edges()

# Se llama cuando el GameManager emite la señal ability_unlocked (al abrir un cofre)
func _on_ability_unlocked(ability: String):
	# De momento solo tenemos la habilidad "roll", pero si añado más en el futuro irían aquí con un elif
	if ability == "roll":
		roll_container.visible = true   # Mostramos la barra de cooldown del roll

func _process(_delta):
	# Si todavía no tenemos el roll desbloqueado, no hace falta actualizar nada cada frame
	if not GameManager.has_roll:
		return
	
	# Buscamos al jugador en el árbol de escena (usamos grupos para encontrarlo sin saber dónde está)
	# get_first_node_in_group devuelve el primer nodo que pertenezca al grupo "player"
	var player = get_tree().get_first_node_in_group("player")
	# Si por alguna razón no encontramos al jugador (cambio de escena, etc.) salimos sin hacer nada
	if player == null:
		return
	
	# Barra llena = listo, barra vaciándose = en cooldown
	var cd = player.roll_cooldown_timer    # Cuánto tiempo queda de cooldown
	var max_cd = player.ROLL_COOLDOWN      # Cooldown máximo (constante del player)
	# Si hay cooldown activo, calculamos el progreso (0 = recién usado, 1 = listo)
	# Si no hay cooldown, la barra está llena del todo (1.0)
	roll_bar.value = 1.0 - (cd / max_cd) if cd > 0 else 1.0
