extends ColorRect  # Este script va en el ColorRect DENTRO del SubViewport

@export var stone: RigidBody3D

func _ready():
	stone = get_node("/root/World/Stone")
	
func _process(delta):
	if stone:
		# Mover este ColorRect dentro del SubViewport
		position.x = stone.position.x * 10
