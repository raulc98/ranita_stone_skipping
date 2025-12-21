extends Button

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
# Acceder directamente por la ruta
	var game_controller = get_node("../../../../GameController")
	if game_controller:
		print("Boton pulsado")
		game_controller.start_game()
