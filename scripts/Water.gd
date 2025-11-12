extends Node3D

@onready var water_area = $water_area
@export var bounce_power: float = 14.0
@export var bounce_damping: float = 0.7
@export var bounce_limit: int = 10

var _bounces: int = 0

signal stone_touched_water(stone)  # Define la señal
signal stone_can_bounce(stone)  # Define la señal

func _ready() -> void:
	print("Aqui escchando....")
	add_to_group("water")
	water_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body) -> void:
	pass
	# Comprueba si el cuerpo que entra es una piedra
	 #and _bounces < bounce_limit:
	#if body.is_in_group("stones") :
		#stone_touched_water.emit(body)  # Emite la señal cuando una piedra toca el agua
		#_bounces += 1
	#if body.is_in_group("stone_ray_cast") :
		#print("Ha colisionado contra el raycast")
		#stone_can_bounce.emit(body)  # Emite la señal la piedra puede rebotar
