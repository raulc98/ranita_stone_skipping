extends Camera3D  # Script en la cámara principal de collision

@export var stone: RigidBody3D

func _ready():
	stone = get_node("/root/World/Stone")

#func _process(delta):
	#if stone:
		#position.x = stone.position.x
		#print("Positiiiion: ", position.x)
