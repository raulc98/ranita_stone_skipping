extends Control

@export var game_scene_path: String = "res://Main.tscn"

func _unhandled_input(event: InputEvent) -> void:
	# Detecta tecla ESPACIO o toque en pantalla
	if (event is InputEventKey and event.pressed and event.keycode == Key.SPACE) \
	   or (event is InputEventScreenTouch and event.pressed):
		start_game()

func start_game() -> void:
	# Cambia a la escena del juego
	var game_scene = load(game_scene_path)
	get_tree().change_scene_to(game_scene)
