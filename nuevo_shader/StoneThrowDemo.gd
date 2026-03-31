## StoneThrowDemo.gd
## Script de demostración: hace rebotar piedras sobre el agua.
## Adjúntalo a un Node3D raíz de tu escena de prueba.
##
## ESTRUCTURA DE ESCENA RECOMENDADA:
##
##  Node3D  (StoneThrowDemo.gd)
##  ├─ Camera3D
##  ├─ DirectionalLight3D
##  ├─ WaterPlane  (MeshInstance3D con PlaneMesh + ShaderMaterial)  ← WaterRippleController.gd
##  ├─ WaterArea   (Area3D)
##  │   └─ CollisionShape3D  (BoxShape3D que cubra el plano)
##  └─ StoneSpawn  (Node3D, marca el punto de lanzamiento)

extends Node3D

@export var water_node   : NodePath   ## Ruta al MeshInstance3D con WaterRippleController
@export var stone_scene  : PackedScene  ## Escena de la piedra (RigidBody3D con MeshInstance3D)
@export var throw_force  : float = 8.0
@export var auto_throw   : bool  = true    ## Lanza piedras automáticamente para probar
@export var auto_interval: float = 1.2

var _water   : Node
var _timer   : float = 0.0

func _ready() -> void:
	_water = get_node(water_node)
	# Conectar el Area3D si existe en la escena
	var area := find_child("WaterArea") as Area3D
	if area:
		area.body_entered.connect(_water._on_area_body_entered)

func _process(delta: float) -> void:
	if not auto_throw:
		return
	_timer += delta
	if _timer >= auto_interval:
		_timer = 0.0
		_throw_random_stone()

	# También lanzamos con clic izquierdo
	if Input.is_action_just_pressed("ui_accept"):
		_throw_random_stone()

func _throw_random_stone() -> void:
	if stone_scene == null:
		# Si no hay escena de piedra, simulamos el impacto directamente
		var rx := randf_range(-4.0, 4.0)
		var rz := randf_range(-4.0, 4.0)
		var hit := Vector3(rx, 0.0, rz)
		_water.spawn_ripple(hit, randf_range(0.5, 1.0))
		return

	var stone : RigidBody3D = stone_scene.instantiate()
	add_child(stone)

	# Posición de lanzamiento: desde arriba con offset aleatorio
	var rx     := randf_range(-3.0, 3.0)
	var rz     := randf_range(-3.0, 3.0)
	stone.global_position = Vector3(rx, 4.0, rz)

	# Impulso hacia abajo
	stone.apply_central_impulse(Vector3(randf_range(-1.0, 1.0), -throw_force, randf_range(-1.0, 1.0)))

	# Limpiamos la piedra después de un rato
	var tween := create_tween()
	tween.tween_interval(4.0)
	tween.tween_callback(stone.queue_free)
