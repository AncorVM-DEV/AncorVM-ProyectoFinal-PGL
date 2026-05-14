extends CharacterBody2D

# --- VARIABLES CONFIGURABLES ---
@export var patrol_left: float = -100.0    # Límite izquierdo de la patrulla (relativo al padre)
@export var patrol_right: float = 100.0    # Límite derecho de la patrulla (relativo al padre)
@export var fly_speed: float = 60.0        # Velocidad de vuelo horizontal
@export var wave_speed: float = 3.0        # Velocidad del movimiento ondulante vertical
@export var wave_amplitude: float = 30.0   # Altura de la onda (cuánto sube y baja)

# Gravedad del proyecto (la necesitamos para que el murciélago caiga al morir)
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Referencias a nuestros nodos
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var hurt_box = $HurtBox         # Detecta el HitBox del jugador (nos golpea)
@onready var damage_zone = $DamageZone   # Detecta el cuerpo del jugador (le hacemos daño al tocarlo)

# --- VARIABLES DE MEMORIA ---
var direction = 1             # Dirección actual (1 = derecha, -1 = izquierda)
var wave_timer = 0.0          # Temporizador para el movimiento ondulante con seno
var hp = 1                    # El murciélago muere de un solo golpe
var is_dead = false           # Si ya estamos muertos paramos la lógica de vuelo
var has_landed = false        # Controla si ya hemos tocado el suelo tras morir (para reanudar la animación)
var start_pos_x: float = 0.0

func _ready():
	add_to_group("enemy")
	start_pos_x = global_position.x
	# Cuando el HitBox del jugador entre en nuestra HurtBox, recibimos daño
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	# Cuando el jugador toque nuestra DamageZone, le hacemos daño
	damage_zone.body_entered.connect(_on_damage_zone_body_entered)
	# Cuando la animación de muerte termine, eliminamos el nodo del árbol
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("fly")

func _physics_process(delta):
	# --- LÓGICA POST-MUERTE ---
	if is_dead:
		if not is_on_floor():
			velocity.x = 0
			velocity.y += gravity * delta
			move_and_slide()
		elif not has_landed:
			has_landed = true
			anim.play("death") 
		return 

	# --- VUELO NORMAL ---

	# Movimiento horizontal de patrulla
	velocity.x = direction * fly_speed

	# ARREGLO BUG: Comprobamos de qué lado está el muro
	if is_on_wall():
		var wall_normal = get_wall_normal().x
		if wall_normal > 0: # Muro a la izquierda, vamos a la derecha
			direction = 1
		elif wall_normal < 0: # Muro a la derecha, vamos a la izquierda
			direction = -1
	
	# Movimiento ondulante vertical
	wave_timer += delta
	velocity.y = sin(wave_timer * wave_speed) * wave_amplitude

	# Giramos al llegar a los límites de la patrulla
	if global_position.x >= start_pos_x + patrol_right:
		direction = -1
	elif global_position.x <= start_pos_x + patrol_left:
		direction = 1

	# Unificamos el giro del sprite aquí al final
	sprite.flip_h = (direction == -1)

	move_and_slide()

# Se llama cuando el HitBox del jugador entra en nuestra HurtBox
func _on_hurt_box_area_entered(area):
	# Comprobamos que el área pertenece al jugador
	if area.get_parent().is_in_group("player"):
		take_damage(1)

# Se llama cuando el cuerpo del jugador toca nuestra DamageZone
func _on_damage_zone_body_entered(body):
	# Le pasamos nuestra posición X para que el jugador sepa hacia dónde tiene que salir empujado
	if body.is_in_group("player") and body.has_method("take_damage_from_enemy"):
		body.take_damage_from_enemy(global_position.x)

func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	# Desactivamos ambas zonas para que no pueda recibir ni hacer más daño
	hurt_box.set_deferred("monitoring", false)
	hurt_box.set_deferred("monitorable", false)
	damage_zone.set_deferred("monitoring", false)
	damage_zone.set_deferred("monitorable", false)
	# Ponemos la animación de muerte en el primer frame y la congelamos
	# El murciélago quedará rígido mientras cae, y al tocar el suelo continuará
	anim.play("death")
	anim.seek(0.0, true)   # Ir al primer frame
	anim.pause()           # Congelar ahí

# Se llama automáticamente cuando cualquier animación termina
func _on_animation_finished(anim_name: StringName):
	if anim_name == "death":
		# La animación de muerte ha terminado: eliminamos el nodo
		queue_free()
