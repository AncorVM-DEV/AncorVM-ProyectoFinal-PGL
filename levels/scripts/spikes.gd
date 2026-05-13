extends Area2D

func _ready():
	# Conectamos la señal body_entered para detectar al jugador
	# Al ser este nodo la propia Area2D no hace falta poner $Area2D.body_entered, basta con body_entered
	body_entered.connect(_on_body_entered)

# Se llama automáticamente cuando un cuerpo entra en la zona de los pinchos
func _on_body_entered(body):
	# Doble comprobación de seguridad:
	# 1. is_in_group("player") -> Solo nos interesa hacer daño al jugador
	# 2. has_method("hit_by_spike") -> Nos aseguramos de que el jugador tenga la función definida
	#    Esto evita errores si algún día otro nodo se mete en el grupo "player" sin tener la función
	if body.is_in_group("player") and body.has_method("hit_by_spike"):
		# Llamamos a la función del Player que gestiona el daño
		# Toda la lógica (quitar vida, respawn, invulnerabilidad, etc.) está en player.gd
		# Los pinchos solo se encargan de avisar
		body.hit_by_spike()
