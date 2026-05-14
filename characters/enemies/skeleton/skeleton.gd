extends CharacterBody2D

# --- VARIABLES CONFIGURABLES ---
@export var patrol_left: float = -80.0     # Límite izquierdo de la patrulla
@export var patrol_right: float = 80.0    # Límite derecho de la patrulla
@export var walk_speed: float = 50.0      # Velocidad de caminar (más lento que el jugador)

# Obtenemos la gravedad por defecto del proyecto
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Referencias a nuestros nodos
@onready var anim = $AnimatedSprite2D
@onready var hurt_box = $HurtBox

# --- VARIABLES DE MEMORIA ---
var direction = 1     # Dirección actual (1 = derecha, -1 = izquierda)
var hp = 2            # El esqueleto aguanta 2 golpes antes de morir
var is_dead = false

func _ready():
	add_to_group("enemy")
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	anim.play("walk")

func _physics_process(delta):
	if is_dead:
		return

	# Aplicamos gravedad para que el esqueleto se quede en el suelo
	if not is_on_floor():
		velocity.y += gravity * delta

	# Movimiento horizontal de patrulla
	velocity.x = direction * walk_speed

	# Damos la vuelta al llegar a los límites
	if global_position.x >= get_parent().global_position.x + patrol_right:
		direction = -1
		anim.flip_h = true
	elif global_position.x <= get_parent().global_position.x + patrol_left:
		direction = 1
		anim.flip_h = false

	move_and_slide()

func _on_hurt_box_area_entered(area):
	if area.get_parent().is_in_group("player"):
		take_damage(1)

func take_damage(amount: int):
	hp -= amount
	# Pequeño parpadeo visual para que el jugador sepa que ha hecho daño
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color(1, 0, 0, 1), 0.05)   # Rojo
	tween.tween_property(anim, "modulate", Color(1, 1, 1, 1), 0.1)    # Normal
	if hp <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	hurt_box.monitoring = false
	hurt_box.monitorable = false
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished
	queue_free()

# Daña al jugador si choca con él físicamente
func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("hit_by_spike"):
		body.hit_by_spike()
