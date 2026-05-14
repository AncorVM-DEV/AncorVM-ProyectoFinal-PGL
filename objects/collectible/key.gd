extends Area2D

# Referencia al reproductor de sonido y al sprite
@onready var sfx = $AudioStreamPlayer
@onready var anim = $AnimatedSprite2D

func _ready():
	# Escuchamos cuando el jugador entra en el área de la llave
	body_entered.connect(_on_body_entered)
	anim.play("idle")

func _on_body_entered(body):
	if body.is_in_group("player"):
		collect()

func collect():
	# Desactivamos la colisión inmediatamente para que no se pueda recoger dos veces
	$CollisionShape2D.set_deferred("disabled", true)
	# Ocultamos el sprite pero dejamos sonar el audio
	anim.visible = false
	# Reproducimos el sonido de recoger llave
	sfx.play()
	# Avisamos al GameManager que hemos recogido una llave
	# Él se encarga de llevar la cuenta y emitir game_won si llegamos a 7
	GameManager.collect_key()
	# Esperamos a que termine el sonido antes de eliminar el nodo
	await sfx.finished
	queue_free()
