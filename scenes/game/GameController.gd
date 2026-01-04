extends Node

signal game_started

var stone: Node

var overlay: Control
var score_label: Label
var meters_label: Label
var game_over_label: Label

var is_game_active: bool = false
var counter_bounces : int = 0

func _ready():
	add_to_group("game_controller")
	init_ui()
	stone.game_over.connect(end_game)
	stone.bounces_updated.connect(count_bounces)

#TODO: NUEVO...
func _process(delta):
	if stone:
		var meters = int(stone.distance_travelled)
		meters_label.text = str(meters) + " m"

func init_ui():
	overlay = get_node("../UI/Overlay")
	stone = get_node("../World/Stone")
	score_label = get_node("../UI/ScoreLabel")
	score_label.text = ""
	game_over_label = get_node("../UI/GameOverLabel")
	game_over_label.hide()
	meters_label = get_node("../UI/MetersLabel")
	meters_label.text = ""
	show_overlay()

func count_bounces():
	counter_bounces += 1
	score_label.text = str(counter_bounces)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		stone_launcher_controller()
	if event.is_action_pressed("reset"):
		print("RESEEEET")
		end_game()
		start_game()
		# Opcional: Consume el evento para que otros nodos no lo procesen
		#get_tree().set_input_as_handled()

func stone_launcher_controller():
	if is_game_active == false:
		start_game()
		return
	if is_game_active == true:
		stone.stone_launcher_controller()

func start_game():
	print("Start_game")
	if not is_game_active:
		counter_bounces = 0;
		score_label.text = str(counter_bounces)
		is_game_active = true
		game_started.emit()
		hide_overlay()
		start_stone()

func start_stone():
	stone.reset_stone()

func end_game():
	if is_game_active:
		game_over_label.show()
		is_game_active = false
		show_overlay()

func show_overlay():
	overlay.visible = true

func hide_overlay():
	overlay.visible = false
	game_over_label.hide()
