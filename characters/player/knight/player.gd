extends CharacterBody2D

# --- VARIABLES CONFIGURABLES ---
const SPEED = 150.0          # Velocidad al caminar
const JUMP_VELOCITY = -300.0 # Fuerza del salto (negativo es hacia arriba en 2D)

# Obtenemos la gravedad por defecto del proyecto de Godot
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Referencias a nuestros nodos (con @onready se cargan al empezar el juego)
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D

# --- VARIABLE DE MEMORIA ---
var was_in_air = false # Esto recuerda si en el frame anterior estábamos volando

func _physics_process(delta):
	# 1. GRAVEDAD: Si no estamos en el suelo, nos caemos.
	if not is_on_floor():
		velocity.y += gravity * delta
		
	# 2 DETECCIÓN DE IMPACTO: Si estábamos en el aire (was_in_air) Y ACABAMOS DE TOCAR EL SUELO (is_on_floor)
	if was_in_air and is_on_floor():
		# Reproducimos la animación 'land' una sola vez.
		# Godot detecta que no tiene bucle y la reproducirá entera.
		anim.play("land")
		
	# Actualizamos la memoria para el próximo frame
	was_in_air = not is_on_floor()

	# 3. SALTO: Accion personlizada Proyecto>Cofig del Proyecto>Mapa De entrada = "jump" (Espacio)
	# Solo saltamos si estamos en el suelo Y no estamos aterrizando (opcional)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 4. MOVIMIENTO HORIZONTAL: Accion personlizada "move_left" (A)(-1) y "move_right" (D)(1)
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		# Si no pulsamos nada, nos frenamos poco a poco
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 5. ACTUALIZAR ANIMACIONES Y DIRECCIÓN
	update_animations(direction)

	# 6. APLICAR MOVIMIENTO (Esta es una función de Godot hace que nos movamos y nos choquemos)
	move_and_slide()

# --- FUNCIÓN PARA CONTROLAR LAS ANIMACIONES ---
func update_animations(direction):
	# Voltea el Sprite dependiendo de hacia dónde miramos
	if direction > 0:
		sprite.flip_h = false # Mirar a la derecha
	elif direction < 0:
		sprite.flip_h = true  # Mirar a la izquierda

		# -- LÓGICA DE PRIORIDAD --
	# Prioridad 1: Si estamos moviéndonos, corremos. Esto cancela el aterrizaje y da fluidez.
	if is_on_floor() and direction != 0:
		anim.play("run") # Si corremos reprocude run
		return # Cortamos la ejecución aquí, no miramos más
		
		# Prioridad 2: Si estamos quietos, comprobamos si la animación de aterrizaje está sonando para no interrumpirla con "idle"
	if anim.current_animation == "land" and anim.is_playing():
		return # No hacemos nada más, dejamos que el choque termine
		
	# Prioridad 3: Lógica normal de aire/suelo
	if is_on_floor():
		if direction == 0:
			anim.play("idle") # Si estamos quietos en el suelo reprocue idle
	else:
		if velocity.y < 0:
			anim.play("jump") # Aqui si saltamos reproduce jump
		else:
			anim.play("fall") # Si caemos repoducira fall
