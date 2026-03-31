extends Node

signal game_started

var stone: Node

var overlay: Control
var score_label: Label
var record_score_label: Label
var meters_label: Label
var record_meters_label: Label
var meters: int = 0
var game_over_label: Label

var is_game_active: bool = false
var counter_bounces : int = 0

var water_blocks: Array = []
var water_blocks_distance: float = 100.0  # Ajusta según tamaño

func _ready():
	init_water_blocks()
	add_to_group("game_controller")
	init_ui()
	stone.game_over.connect(end_game)
	stone.bounces_updated.connect(count_bounces)
	update_record()
func init_water_blocks():
	#water_blocks = [
		#get_node("Water_0"),
		#get_node("Water_1"), 
		#get_node("Water_2"),
		#get_node("Water_3")
	#]
	water_blocks = [
		get_node("/root/World/Water_0"),
		get_node("/root/World/Water_1"),
		get_node("/root/World/Water_2"), 
		get_node("/root/World/Water_3")
	]

	# 2. Conectar señales de cada bloque
	for block in water_blocks:
		if block.has_signal("pass_water_block"):
			block.pass_water_block.connect(water_block_passed)

func water_block_passed(pass_water_block):
	var index = water_blocks.find(pass_water_block)
	if index == -1:
		return
	if index == 0:
		var last_water_block = water_blocks[-1]
		var new_position = last_water_block.position.x + water_blocks_distance - 1
		water_blocks[0].position.x = new_position
		
		var moved_block = water_blocks.pop_front()
		water_blocks.append(moved_block)
		for i in range(water_blocks.size()):
			print(i, ": ", water_blocks[i].name)
	pass

#TODO: NUEVO...
func _process(delta):
	if stone:
		meters = int(stone.distance_travelled)
		meters_label.text = str(meters) + " m"

func init_ui():
	overlay = get_node("../UI/Overlay")
	stone = get_node("/root/World/Stone")  # Ruta absoluta
	#stone = get_node("../World/Stone")
	score_label = get_node("../UI/ScoreLabel")
	score_label.text = ""
	record_score_label = get_node("../UI/RecordScoreLabel")
	record_score_label.text = ""
	game_over_label = get_node("../UI/GameOverLabel")
	game_over_label.hide()
	meters_label = get_node("../UI/MetersLabel")
	meters_label.text = ""
	record_meters_label = get_node("../UI/RecordMetersLabel")
	record_meters_label.text = ""
	show_overlay()

func count_bounces():
	counter_bounces += 1
	score_label.text = str(counter_bounces)
	SaveSystem.save_record(counter_bounces, meters)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		print("AAAAAAAAAAAAA")
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
		update_record()

func update_record():
	record_score_label.text = str(SaveSystem.bounces_record)
	record_meters_label.text = str(SaveSystem.distance_record)
	pass

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
