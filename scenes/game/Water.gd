extends Area3D

# Parámetros de la onda (debe coincidir con tu shader)
var t := 0.0  # tiempo acumulado
var wave_amplitude = 0.2   # altura máxima de la ola
var wave_length = 2.0      # longitud de la onda
var wave_speed = 1.0       # velocidad de animación

func _process(delta):
	t += delta  # acumula tiempo cada frame
	for body in get_overlapping_bodies():
		# Solo aplica a cuerpos que sean PhysicsBody3D
		if body is RigidBody3D or body is CharacterBody3D:
			var water_y = get_water_height(body.global_position.x, body.global_position.z)
			body.global_position.y = lerp(body.global_position.y, water_y, 0.1)
		# Ajusta el cuerpo si está debajo de la superficie de agua
			if body.global_position.y < water_y:
				body.global_position.y = water_y
				
func get_water_height(x: float, z: float) -> float:
	var y = sin(x / wave_length + t * wave_speed) * wave_amplitude
	y += cos(z / wave_length + t * wave_speed) * wave_amplitude
	return y
