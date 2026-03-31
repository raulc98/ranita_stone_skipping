extends TextureButton

@onready var animaciones = [
	$Animacion1,
	$Animacion2,
	$Animacion3,
	$Animacion4
]

var activas = []

func _ready():
	pressed.connect(_on_boton_pulsado)
	
	for anim in animaciones:
		anim.frame = 0
		anim.stop()
		anim.visible = false
		anim.animation_finished.connect(_on_animacion_terminada.bind(anim))

func _on_boton_pulsado():
# Crear un evento de TECLA (no de acción)
	var evento_tecla = InputEventKey.new()
	evento_tecla.keycode = KEY_SPACE  # Código de la tecla espacio
	evento_tecla.pressed = true

	# Enviar el evento al sistema
	Input.parse_input_event(evento_tecla)
	
	# 👇 TU LÓGICA DE ANIMACIÓN (sin cambios)
	var anim_disponible = null
	for anim in animaciones:
		if not activas.has(anim):
			anim_disponible = anim
			break
	
	if anim_disponible:
		anim_disponible.frame = 0
		anim_disponible.visible = true
		anim_disponible.play("wave")
		activas.append(anim_disponible)

func _on_animacion_terminada(anim):
	activas.erase(anim)
	anim.visible = false
	anim.stop()
	anim.frame = 0
