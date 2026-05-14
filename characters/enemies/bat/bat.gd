extends CharacterBody2D

# --- VARIABLES CONFIGURABLES ---
@export var patrol_left: float = -100.0    # Límite izquierdo de la patrulla (coordenada local)
@export var patrol_right: float = 100.0    # Límite derecho de la patrulla (coordenada local)
@export var fly_speed: float = 60.0        # Velocidad de vuelo horizontal
@export var wave_speed: float = 3.0        # Velocidad del movimiento ondulante vertical
@export var wave_amplitude: float = 30.0   # Altura de la onda vertical

# Referencias a nuestros nodos
@onready var anim = $AnimatedSprite2D
@onready var hurt_box = $HurtBox

# --- VARIABLES DE MEMORIA ---
var direction = 1         # Dirección actual (1 = derecha, -1 = izquierda)
var wave_timer = 0.0      # Temporizador para el movimiento ondulante
var hp = 1                # Vida del murciélago (muere de un solo golpe)
var is_dead = false       # Si ya está muerto no procesamos nada más

func _ready():
	add_to_group("enemy")
	# Escuchamos cuando el HitBox del jugador entra en nuestra HurtBox
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	anim.play("fly")

func _physics_process(delta):
	if is_dead:
		return

	# Movimiento horizontal de patrulla entre los dos límites
	velocity.x = direction * fly_speed

	# Movimiento ondulante vertical usando una función seno para que vuele de forma natural
	wave_timer += delta
	velocity.y = sin(wave_timer * wave_speed) * wave_amplitude

	# Si llegamos a los límites de la patrulla, damos la vuelta
	# Usamos posición global para que los límites funcionen en el mundo, no en coordenadas del padre
	if global_position.x >= get_parent().global_position.x + patrol_right:
		direction = -1
		anim.flip_h = true   # Damos la vuelta al sprite cuando cambiamos de dirección
	elif global_position.x <= get_parent().global_position.x + patrol_left:
		direction = 1
		anim.flip_h = false

	move_and_slide()

# Detecta cuando el jugador nos golpea con su HitBox
func _on_hurt_box_area_entered(area):
	# Comprobamos que el área que nos golpeó pertenece a un nodo del grupo "player"
	if area.get_parent().is_in_group("player"):
		take_damage(1)

# Recibe daño y muere si se le acaban los HP
func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	# Desactivamos la HurtBox para que no pueda recibir más daño ni hacérselo al jugador
	hurt_box.monitoring = false
	hurt_box.monitorable = false
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
		# Esperamos a que termine la animación de muerte antes de eliminar el nodo
		await anim.animation_finished
	queue_free()   # Eliminamos el nodo del árbol de escena

# Se llama cuando el jugador toca el cuerpo del murciélago (colisión física)
func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("hit_by_spike"):
		body.hit_by_spike()   # Reutilizamos la función de daño del jugador
