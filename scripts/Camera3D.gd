extends Camera3D

@export var piedra_path: NodePath  # Referencia a la piedra
@export var distancia: Vector3 = Vector3(0, 2, 6)  # Y=altura, Z=distancia detrás (Z positivo = detrás si miramos hacia adelante)
@export var suavizado: float = 5.0  # Cuanto más alto, más suave el movimiento

var piedra: RigidBody3D

func _ready():
	piedra = get_node(piedra_path)

func _physics_process(delta):
	if not piedra:
		return

	# Calculamos la posición deseada detrás de la piedra según su dirección
	var direccion_atras = piedra.transform.basis.z.normalized()
	var posicion_deseada = piedra.global_transform.origin \
						  + (direccion_atras * distancia.z) \
						  + (Vector3.UP * distancia.y)

	# Movemos la cámara suavemente hacia esa posición
	global_transform.origin = global_transform.origin.lerp(posicion_deseada, suavizado * delta)

	# Miramos hacia la piedra
	look_at(piedra.global_transform.origin, Vector3.UP)
