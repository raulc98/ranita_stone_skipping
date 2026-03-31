extends Node3D

@onready var water_area = $water_area
@onready var water_move = $water_move
@onready var water_shader = $water_shader  # Referencia al MeshInstance3D
#@onready var water_move =   #$water_move

@export var bounce_power: float = 14.0
@export var bounce_damping: float = 0.7
@export var bounce_limit: int = 10
@export var is_only_shader: int = 0

var _bounces: int = 0

signal stone_touched_water(stone)  # Define la señal
signal stone_can_bounce(stone)  # Define la señal

@export var first_position_x: float

func _ready() -> void:
	var water = self
	var sim_tex =  $Simulation.get_texture()
	var col_tex =  $Collision.get_texture() #get_node("/root/World/Collision").get_texture()
	
	if water_shader and water_shader.mesh:
		water_shader.mesh.surface_get_material(0).set_shader_parameter('simulation', sim_tex)
	
	add_to_group("water")
	# water_area.body_entered.connect(_on_body_entered)
	water_move.body_entered.connect(_on_body_entered)
	first_position_x = position.x
	var game_controller = get_tree().get_first_node_in_group("game_controller")
	game_controller.game_started.connect(on_reset_water)

func _on_body_entered(body) -> void:
	if body.is_in_group("stones") && is_only_shader == 0:
		#await get_tree().create_timer(2.0).timeout
		position.x += 400.0
	pass

func on_reset_water():
	print("VOLVIENDO A MI POSICIOOOON:", first_position_x)
	position.x = first_position_x
 
