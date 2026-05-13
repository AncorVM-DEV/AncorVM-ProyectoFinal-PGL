extends CharacterBody2D

# --- VARIABLES CONFIGURABLES ---
const SPEED = 150.0          # Velocidad al caminar
const JUMP_VELOCITY = -400.0 # Fuerza del salto (negativo es hacia arriba en 2D)
const WALL_SLIDE_SPEED = 200.0 # Velocidad máxima al resbalar
const WALL_JUMP_PUSH = 300.0 # Fuerza para separarse de la pared al saltar

# Obtenemos la gravedad por defecto del proyecto de Godot
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Referencias a nuestros nodos (con @onready se cargan al empezar el juego)
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D

# --- VARIABLES DE MEMORIA ---
var was_in_air = false # Esto recuerda si en el frame anterior estábamos volando
var wall_jump_timer = 0.0 # Temporizador seguro para bloquear el control al rebotar en la pared

func _physics_process(delta):
	# 0. ACTUALIZAR EL TEMPORIZADOR
	if wall_jump_timer > 0:
		wall_jump_timer -= delta

	# 1. GRAVEDAD Y RESBALAR EN PARED: Si no estamos en el suelo, nos caemos o resbalamos por la pared.
	if not is_on_floor():
		# Si estamos tocando SOLO la pared y cayendo (velocity.y > 0)
		if is_on_wall_only() and velocity.y > 0:
			# Resbalamos a la velocidad configurada
			velocity.y = min(velocity.y + gravity * delta, WALL_SLIDE_SPEED)
		else:
			# Caída normal
			velocity.y += gravity * delta
		
	# 2 DETECCIÓN DE IMPACTO: Si estábamos en el aire (was_in_air) y acabamos de tocar el suelo (is_on_floor)
	if was_in_air and is_on_floor():
		# Reproducimos la animación 'land' una sola vez.
		# Godot detecta que no tiene bucle y la reproducirá entera.
		anim.play("land")
		
	# Actualizamos la memoria para el próximo frame
	was_in_air = not is_on_floor()

	# 3. SALTO Y WALL JUMP: Accion personalizada Proyecto>Config del Proyecto>Mapa de entrada = "jump" (Espacio)
	# Solo saltamos si estamos en el suelo, o saltamos desde la pared si estamos tocando solo la pared
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif is_on_wall_only():
			# Salto desde la pared y calculamos la dirección de rebote
			# get_wall_normal().x nos da la dirección contraria a la pared (1 o -1)
			var wall_normal = get_wall_normal().x
			velocity.y = JUMP_VELOCITY
			velocity.x = wall_normal * WALL_JUMP_PUSH
			
			# Bloqueamos el control por un breve tiempo para permitir el arco del salto
			wall_jump_timer = 0.3

	# 4. MOVIMIENTO HORIZONTAL: Accion personalizada "move_left" (A)(-1) y "move_right" (D)(1)
	var direction = Input.get_axis("move_left", "move_right")
	
	# Solo obedecemos al teclado si el temporizador de rebote ha llegado a 0
	if wall_jump_timer <= 0:
		if direction:
			velocity.x = direction * SPEED
		else:
			# Si no pulsamos nada, nos frenamos poco a poco
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# 5. ACTUALIZAR ANIMACIONES Y DIRECCIÓN
	update_animations(direction)

	# 6. APLICAR MOVIMIENTO (Esta es una función de Godot que hace que nos movamos y nos choquemos)
	move_and_slide()


# --- FUNCIÓN PARA CONTROLAR LAS ANIMACIONES ---
func update_animations(direction):
	# Voltea el Sprite dependiendo de hacia dónde miramos (si no estamos en la pared)
	if direction > 0 and not is_on_wall_only():
		sprite.flip_h = false 
	elif direction < 0 and not is_on_wall_only():
		sprite.flip_h = true

	# -- LÓGICA DE PRIORIDAD --

	# Prioridad 1: Si estamos moviéndonos, corremos. Esto cancela el aterrizaje y da fluidez.
	if is_on_floor() and direction != 0:
		anim.play("run") # Si corremos reproduce run
		return # Cortamos la ejecución aquí, no miramos más
		
	# Prioridad 2: Esto lo pongo aqui para que tenga prioridad el jump antes que el "land" instantáneamente.
	if velocity.y < 0:
		# anim.assigned_animation esto hace que la animacion se congele en el ultimo farme y no cree un bucle constante (a pesar de estar desactivado)
		if anim.assigned_animation != "jump":
			anim.play("jump") # Aqui si saltamos reproduce jump
		return
	# Prioridad 3: Si estamos quietos, comprobamos si la animación de aterrizaje está sonando para no interrumpirla con "idle"
	if anim.current_animation == "land" and anim.is_playing():
		return # No hacemos nada más, dejamos que el choque termine
		
	# Prioridad 4: Lógica normal de aire/suelo/pared
	if is_on_floor():
		if direction == 0:
			anim.play("idle") # Si estamos quietos en el suelo reproduce idle
	else:
		if is_on_wall_only() and velocity.y > 0:
			if anim.assigned_animation != "wall_slide":
				anim.play("wall_slide") # Si estamos en la pared deslizandonos reproduce wall_slide
			# Forzamos al caballero a mirar hacia la pared
			sprite.flip_h = get_wall_normal().x > 0
		else:
			if anim.assigned_animation != "fall":
				anim.play("fall") # Si caemos repoducira fall
	
