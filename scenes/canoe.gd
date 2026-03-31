extends Node3D

@export var intensidad_min: float = 2.0
@export var intensidad_max: float = 4.0
@export var velocidad_min: float = 0.8
@export var velocidad_max: float = 1.5

var tiempo: float = 0.0
var mi_intensidad: float
var mi_velocidad: float
var mi_desfase: float

func _ready():
	randomize()
	# Cada canoa tendrá valores completamente distintos
	mi_intensidad = randf_range(intensidad_min, intensidad_max)
	mi_velocidad = randf_range(velocidad_min, velocidad_max)
	mi_desfase = randf_range(0, 6.28)

func _process(delta):
	tiempo += delta * mi_velocidad
	
	# Cada canoa se mueve a su propio ritmo
	rotation_degrees.z = sin(tiempo + mi_desfase) * mi_intensidad
