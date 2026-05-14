extends CharacterBody2D

# --- VARIABLES CONFIGURABLES ---
const SPEED = 150.0          # Velocidad al caminar
const JUMP_VELOCITY = -400.0 # Fuerza del salto (negativo es hacia arriba en 2D)
const WALL_SLIDE_SPEED = 200.0 # Velocidad máxima al resbalar
const WALL_JUMP_PUSH = 300.0 # Fuerza para separarse de la pared al saltar
	# --- Habilidad ROLL ---
const ROLL_SPEED = 350.0      # Velocidad horizontal durante el roll (más rápida que correr)
const ROLL_DURATION = 0.4     # Cuánto dura el roll en segundos
const ROLL_COOLDOWN = 1.0     # Tiempo de espera antes de poder volver a rodar

# --- Habilidad ATAQUE ---
const ATTACK_DURATION = 0.5   # Cuánto dura la animación del ataque en segundos

# Estado del ataque
var is_attacking = false       # Si estamos atacando ahora mismo
var attack_timer = 0.0        # Tiempo que le queda a la animación de ataque

# Obtenemos la gravedad por defecto del proyecto de Godot
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Referencias a nuestros nodos (con @onready se cargan al empezar el juego)
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var hit_box = $HitBox  # El área que golpea a los enemigos durante el ataque

# --- VARIABLES DE MEMORIA ---
var was_in_air = false # Esto recuerda si en el frame anterior estábamos volando
var wall_jump_timer = 0.0 # Temporizador seguro para bloquear el control al rebotar en la pared

	# --- Estado del Roll ---
var is_rolling = false           # Si estamos rodando ahora mismo
var roll_timer = 0.0             # Cuánto tiempo le queda al roll actual
var roll_cooldown_timer = 0.0    # Tiempo restante hasta poder volver a rodar
var roll_direction = 1           # Dirección del roll (1 derecha, -1 izquierda)

	# Estado daño/muerte
var is_invulnerable = false  # Si es true los pinchos no nos hacen daño (activo durante el roll y el respawn)
var is_dead = false          # Si estamos muertos, paramos toda la lógica de movimiento


func _ready():
	# Nos añadimos al grupo "player" para que otros scripts (pinchos, cofre, puerta) nos detecten
	add_to_group("player")
	# Escuchamos la señal de muerte del GameManager para reaccionar cuando nos quedemos sin vidas
	GameManager.player_died.connect(_on_player_died)
	# Guardamos la posición inicial como punto de respawn por defecto
	GameManager.respawn_position = global_position
	# Empezamos con el hitbox desactivado: solo se activa cuando atacamos
	hit_box.monitoring = false


func _physics_process(delta):
	# Si estamos muertos no procesamos nada (se ejecuta la animación de muerte aparte)
	if is_dead:
		return
	
	# 0. ACTUALIZAR LOS TEMPORIZADORES
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
	if roll_cooldown_timer > 0:
		roll_cooldown_timer -= delta
		
	# ATAQUE: si estamos atacando, actualizamos el timer y desactivamos el hitbox al terminar
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			end_attack()
	# INICIAR ATAQUE: Acción "attack" en el Input Map (tecla Z o clic izquierdo)
	# Podemos atacar si no estamos rodando ni ya atacando
	if Input.is_action_just_pressed("attack") and not is_rolling and not is_attacking:
		start_attack()

	# SI ESTAMOS RODANDO: el roll tiene control total del movimiento, ignoramos el input normal
	if is_rolling:
		roll_timer -= delta
		velocity.x = roll_direction * ROLL_SPEED
		# Aplicamos gravedad por si rodamos por un borde
		if not is_on_floor():
			velocity.y += gravity * delta
		# Cuando se acaba el roll volvemos a la lógica normal
		if roll_timer <= 0:
			end_roll()
		move_and_slide()
		return # No ejecutamos el resto del physics_process mientras rodamos

	# INICIAR ROLL: Acción personalizada "roll" (Shift) - Solo si tenemos la habilidad desbloqueada
	if Input.is_action_just_pressed("roll") and can_roll():
		start_roll()
		return
	
	

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


# --- FUNCIONES DE ROLL ---

# Comprueba si se cumplen TODAS las condiciones para poder rodar
func can_roll() -> bool:
	return GameManager.has_roll \
		and roll_cooldown_timer <= 0 \
		and not is_rolling \
		and is_on_floor()  # Solo se puede rodar en el suelo, no en el aire

# Arranca el roll: activa la invulnerabilidad y reproduce la animación
func start_roll():
	is_rolling = true
	is_invulnerable = true
	roll_timer = ROLL_DURATION
	# Rodamos hacia donde estemos mirando (sprite.flip_h indica si miramos a la izquierda)
	roll_direction = -1 if sprite.flip_h else 1
	anim.play("roll")

# Termina el roll: quita la invulnerabilidad y arranca el cooldown
func end_roll():
	is_rolling = false
	is_invulnerable = false
	roll_cooldown_timer = ROLL_COOLDOWN


# --- FUNCIONES DE DAÑO Y MUERTE ---

# Esta función la llama el script de los pinchos cuando nos tocan
func hit_by_spike():
	# Si estamos rodando o ya muertos, ignoramos el daño
	if is_invulnerable or is_dead:
		return
	GameManager.take_damage()
	# Si aún quedan vidas, respawneamos en el punto inicial del nivel
	if GameManager.lives > 0:
		respawn()
	# Si ya no quedan vidas, el GameManager emite player_died y se llama _on_player_died()

# Nos teletransporta al punto de respawn con una breve invulnerabilidad y parpadeo
func respawn():
	is_invulnerable = true
	velocity = Vector2.ZERO
	global_position = GameManager.respawn_position
	# Parpadeo visual para indicar que somos invulnerables temporalmente
	var blink_tween = create_tween().set_loops(6)
	blink_tween.tween_property(sprite, "modulate:a", 0.3, 0.1)
	blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	await get_tree().create_timer(1.2).timeout
	is_invulnerable = false

# Se llama cuando el GameManager emite la señal player_died (vidas = 0)
func _on_player_died():
	is_dead = true
	velocity = Vector2.ZERO
	# Reproducimos la animación de muerte si existe
	if anim.has_animation("death"):
		anim.play("death")
	

# Arranca el ataque: activa el hitbox y reproduce la animación
func start_attack():
	is_attacking = true
	attack_timer = ATTACK_DURATION
	anim.play("sword_attack")
	# Activamos el hitbox para que detecte enemigos
	hit_box.monitoring = true
	# Ajustamos la posición del hitbox según la dirección en la que miramos
	# Si miramos a la izquierda (flip_h = true) movemos el hitbox a la izquierda también
	hit_box.position.x = abs(hit_box.position.x) * (-1 if sprite.flip_h else 1)

# Termina el ataque: desactiva el hitbox
func end_attack():
	is_attacking = false
	hit_box.monitoring = false


# --- FUNCIÓN PARA CONTROLAR LAS ANIMACIONES ---
func update_animations(direction):
	# Voltea el Sprite dependiendo de hacia dónde miramos (si no estamos en la pared)
	if direction > 0 and not is_on_wall_only():
		sprite.flip_h = false 
	elif direction < 0 and not is_on_wall_only():
		sprite.flip_h = true

	# -- LÓGICA DE PRIORIDAD --
	
	# Prioridad 0: si estamos atacando, la animación de ataque no se interrumpe
	if is_attacking:
		return  # No dejamos que ninguna otra animación se superponga al ataque
	
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
