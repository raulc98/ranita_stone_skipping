extends Node3D

@export var stone: RigidBody3D
@export var water_half_width: float = 50.0   # La piedra falsa se mueve entre -50 y 50
@export var water_half_height: float = 50.0  # Entre -50 y 50

func _ready():
	if not stone:
		stone = get_node("/root/World/Stone")

func _process(delta):
	if not stone:
		return
	
	# Wrap en X entre -water_half_width y +water_half_width
	var wrapped_x = wrapf_centered(stone.position.x, water_half_width)
	
	# Wrap en Y entre -water_half_height y +water_half_height
	var wrapped_y = wrapf_centered(stone.position.y, water_half_height)
	
	position = Vector3(wrapped_x, wrapped_y, stone.position.z)
	
	# if Engine.get_frames_drawn() % 60 == 0:
	# 	print("Piedra: ", stone.position.x, " → Colisión: ", wrapped_x)

func wrapf_centered(value: float, limit: float) -> float:
	var range_val = limit * 2
	var wrapped = fmod(value + limit, range_val)
	if wrapped < 0:
		wrapped += range_val
	return wrapped - limit
