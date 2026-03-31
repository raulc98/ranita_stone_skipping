extends SubViewport

@export var stone: RigidBody3D

func _process(delta):
	if stone:
		# Acceder al padre (que debe ser un Node3D)
		var parent = get_parent()
		if parent is Node3D:
			parent.position.x = stone.position.x
