extends Camera3D

@export var stone: RigidBody3D
@export var suavizado: float = 4.0

# POSICIÓN RELATIVA A LA PIEDRA
@export var offset: Vector3 = Vector3(-3, 5, -5)  # X=0 (misma X), Y=8 (altura), Z=-5 (detrás)

# INCLINACIÓN
@export var inclinacion: float = -0.40

# ALTURA FIJA DE LA CÁMARA (puedes ajustarla desde el inspector)
@export var altura_fija: float = 10.0

func _ready():
	if not stone:
		stone = get_node_or_null("/root/World/Stone")

func _physics_process(delta):
	if not stone:
		return
	
	# ANCHOR: 1. POSICIÓN - SOLO seguimos en X, la Y es fija
	var posicion_deseada = Vector3(
		stone.global_transform.origin.x + offset.x,  # X sigue a la piedra
		altura_fija,                                   # Y es fija (no sigue el rebote)
		stone.global_transform.origin.z + offset.z    # Z mantiene el offset
	)
	
	# ANCHOR: 2. Movimiento suave (solo en X y Z, Y se mantiene fija)
	var nueva_posicion = global_transform.origin.lerp(
		posicion_deseada,
		suavizado * delta
	)
	# Aseguramos que Y se mantenga exactamente en altura_fija
	nueva_posicion.y = altura_fija
	global_transform.origin = nueva_posicion
	
	# ANCHOR: 3. MIRADA - Hacia adelante (basado en velocidad X)
	var velocidad = abs(stone.linear_velocity.x)
	var distancia_adelante = clamp(velocidad * 2.0, 5.0, 15.0)
	
	var punto_mirada = global_transform.origin + Vector3(
		distancia_adelante,
		inclinacion * distancia_adelante,
		0
	)
	look_at(punto_mirada, Vector3.UP)
