extends CharacterBody2D

# --- VARIABLES CONFIGURABLES ---
@export var patrol_left: float = -80.0    # Límite izquierdo de la patrulla
@export var patrol_right: float = 80.0    # Límite derecho de la patrulla
@export var walk_speed: float = 50.0      # Velocidad al caminar (más lento que el jugador)

# Gravedad del proyecto para que el esqueleto se quede en el suelo
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Referencias a nuestros nodos
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var hurt_box = $HurtBox
@onready var damage_zone = $DamageZone

# --- VARIABLES DE MEMORIA ---
var direction = 1      # Dirección actual de la patrulla
var hp = 2             # El esqueleto aguanta 2 golpes
var is_dead = false
var start_pos_x: float = 0.0

func _ready():
	add_to_group("enemy")
	start_pos_x = global_position.x # Memoriza su posición inicial
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	damage_zone.body_entered.connect(_on_damage_zone_body_entered)
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("walk")

func _physics_process(delta):
	if is_dead:
		return

	# Gravedad
	if not is_on_floor():
		velocity.y += gravity * delta

	# 1. Aplicamos la velocidad horizontal
	velocity.x = direction * walk_speed
	
	# 2. PRIMERO nos movemos (aquí Godot calcula los choques reales)
	move_and_slide()

	# 3. DESPUÉS comprobamos si nos hemos chocado con la pared
	if is_on_wall():
		direction *= -1
		
	# 4. Comprobamos la patrulla invisible (por si no hay muro pero llega al límite)
	if global_position.x >= start_pos_x + patrol_right:
		direction = -1
	elif global_position.x <= start_pos_x + patrol_left:
		direction = 1

	# 5. Giramos el sprite y aplicamos la animación
	sprite.flip_h = (direction == -1)

	if is_on_floor() and anim.current_animation != "walk":
		anim.play("walk")

func _on_hurt_box_area_entered(area):
	if area.get_parent().is_in_group("player"):
		take_damage(1)

func _on_damage_zone_body_entered(body):
	# Le pasamos nuestra posición X para que el jugador sepa hacia dónde tiene que salir empujado
	if body.is_in_group("player") and body.has_method("take_damage_from_enemy"):
		body.take_damage_from_enemy(global_position.x)

func take_damage(amount: int):
	hp -= amount
	# Parpadeo rojo para dar feedback visual de que hemos recibido daño
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.2, 0.2, 1), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.1)
	if hp <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	hurt_box.set_deferred("monitoring", false)
	hurt_box.set_deferred("monitorable", false)
	damage_zone.set_deferred("monitoring", false)
	damage_zone.set_deferred("monitorable", false)
	anim.play("death")

func _on_animation_finished(anim_name: StringName):
	if anim_name == "death":
		queue_free()
