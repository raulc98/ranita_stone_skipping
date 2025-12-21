extends Control

@export var game_scene: PackedScene

func _ready() -> void:
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE) \
	   or (event is InputEventScreenTouch and event.pressed):
		start_game()

func start_game() -> void:
	if game_scene:
		get_tree().change_scene_to(game_scene)
	else:
		push_error("game_scene en Menu.gd no está configurada.")
