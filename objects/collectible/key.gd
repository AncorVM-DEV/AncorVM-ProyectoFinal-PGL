extends Area2D

# Referencia al reproductor de sonido y al sprite
@onready var sfx = $AudioStreamPlayer

func _ready():
	# Escuchamos cuando el jugador entra en el área de la llave
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		collect()

func collect():
	# Desactivamos la colisión inmediatamente para que no se pueda recoger dos veces
	$CollisionShape2D.set_deferred("disabled", true)
	# Avisamos al GameManager que hemos recogido una llave
	# Él se encarga de llevar la cuenta y emitir game_won si llegamos a 7
	GameManager.collect_key()
	# Le pasamos el reproductor de sonido al GameManager
	sfx.reparent(GameManager)
	# Reproducimos el sonido de recoger llave
	sfx.play()
	
	# Aqui el sonido se auto-destruya cuando acaba para si no dejar basura en la memoria RAM
	sfx.finished.connect(sfx.queue_free)
	queue_free()
