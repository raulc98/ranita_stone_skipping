extends RigidBody3D

@export var power_launch: float = 20.0
@export var relative_up: float = 0.3         # fracción de la potencia hacia arriba para generar arco
@onready var down_ray: RayCast3D = $down_ray
@onready var stone_area: Area3D = $stone_area


@onready var aim_ray: RayCast3D = $aim_ray   # asegúrate de tener este nodo en la escena
@export var aim_min_y: float = -1.3
@export var aim_max_y: float = 1.3
@export var aim_min_z: float = 0.2
@export var aim_max_z: float = 2
@export var aim_speed: float = 4

var _aim_phase: float = 0.0 #TODO: esto no se que hace... consultar...
var aim_active: bool = true #Controla si la aguja oscila

# Parámetros ajustables
var can_bounce: bool = false  # Controla si la piedra puede rebotar
var bounce_restitution: float = 0.6   # 1.0 = sin pérdida, 0.5 = pierde la mitad de la energía
var bounce_up_boost: float = 4.0      # empuje extra vertical tras el rebote
var min_bounce_speed: float = 6     # Limite de velocidad a la que la piedra rebota
var bounces_counter : int = 0

# Configurable
var	is_power_selected: bool = false
var is_first_launched: bool = true # Controla si la piedra esta lanzada por primera vez
var is_game_over: bool = false

var initial_transform: Transform3D
var initial_aim_target: Vector3

func _ready() -> void:
	initial_transform = global_transform
	if aim_ray:
		initial_aim_target = aim_ray.target_position
	add_to_group("stones")
	freeze = true
	down_ray.enabled = true
	stone_area.area_entered.connect(_on_area_entered)
	

func first_launch_controller(delta: float):
	if is_first_launched and aim_active and aim_ray:
		_aim_phase += aim_speed * delta
		var tp : Vector3
		# valor entre 0 y 1 con una senoide para movimiento suave
		if not is_power_selected:
			var t: float = (sin(_aim_phase) + 1.0) * 0.5
			var new_z: float = lerp(aim_min_z, aim_max_z, t)
			tp = aim_ray.target_position
			tp.z = new_z
		else:
			var t: float = (sin(_aim_phase) + 1.0) * 0.5
			var new_y: float = lerp(aim_min_y, aim_max_y, t)
			tp = aim_ray.target_position
			tp.y = new_y
		aim_ray.target_position = tp
		aim_ray.force_raycast_update()

# Controla cuando el raycast colisiona con el agua...
func _physics_process(delta: float) -> void:
	first_launch_controller(delta)
	if down_ray.is_colliding() and down_ray.get_collider().is_in_group("water") and not freeze and linear_velocity.y <= 0:
		slow_down_time()
		can_bounce = true
	else:
		normal_speed_time()
		can_bounce = false

# Controla cuando la piedra colisiona con el agua
func _on_area_entered(area):
	if area.is_in_group("water"):
		print("Colisionando contra el agüita...")
		bounce_stone_with_water(Vector3.UP)
	if area.is_in_group("water_bottom"):
		print("Game Over... :(")
		is_game_over = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		stone_launcher()

var contactos: int = 0
# Metodos para lanzar y hacer rebotar la piedra
func stone_launcher() -> void:
	if is_game_over:
		reset_stone()		
		return
	if is_first_launched:
		if not is_power_selected:
			is_power_selected = true
			var velocity_multiplier = 0.5
			print("Power launch: ", power_launch)
			print("Aim ray tamaño: ", aim_ray.target_position)
			if aim_ray.target_position.z > 1.4:
				velocity_multiplier = 1	
			power_launch = power_launch * aim_ray.target_position.z * velocity_multiplier
			print("Final Power launch: ", power_launch)
			return
		freeze = false
		is_first_launched = false
		var dir: Vector3
		if aim_ray:
			var global_target: Vector3 = aim_ray.to_global(aim_ray.target_position)
			dir = (global_target - global_transform.origin).normalized()
			# <-- AÑADIR: orientar la piedra para que su "frente" mire al objetivo
			look_at(global_target, Vector3.UP)
		else:
			dir = -transform.basis.z.normalized()

		var impulso: Vector3 = dir * power_launch + Vector3.UP * (power_launch * relative_up)
		apply_central_impulse(impulso)
		aim_ray.enabled = false
		aim_ray.hide()
		return
	
	if can_bounce && is_first_launched == false:
		contactos += 1
		print("toque: ", contactos)
		var v: Vector3 = linear_velocity
	# 2) Evitar rebotes insignificantes
		print("Velocidad actual:" , v.length())
		print("Min bounce speed:" , min_bounce_speed)
		if v.length() > min_bounce_speed:
			print("Velocidad correcta")
			throw_stone()
		else:
			print("Velocidad demasiado baja...");
		can_bounce = false
		#if down_ray.target_position.z > 0.2 and down_ray.target_position.z < 0.8:
			#down_ray.target_position.z += 0.2
		if Engine.time_scale > 1:
			Engine.time_scale -= 0.05
		return
	elif not can_bounce:
		if down_ray.target_position.z > 0.2:
			down_ray.target_position.z -= 0.2
		if Engine.time_scale < 1.8:
			speed_up_time()
		return


func throw_stone(contact_normal: Vector3 = Vector3.UP) -> void :
	var v: Vector3 = linear_velocity * 1.2
	var n: Vector3 = contact_normal.normalized()
	var v_reflected: Vector3 = v - 2.0 * v.dot(n) * n
	var new_velocity: Vector3 = v_reflected * (bounce_restitution + 0.4)
	if new_velocity.dot(n) < 0.1:
		new_velocity += n * bounce_up_boost
	linear_velocity = new_velocity
	position += n * 0.05
	bounces_counter += 1
	pass
  
# Rebote al tocar el agua, ya no puedes pulsar...
func bounce_stone_with_water(contact_normal: Vector3 = Vector3.UP) -> void:
	down_ray.target_position.z = 0
	# contact_normal se puede pasar si detectas la normal del agua en el contacto,
	# por defecto usamos Vector3.UP
	var v: Vector3 = linear_velocity
	# 2) Evitar rebotes insignificantes
	if v.length() < min_bounce_speed:
		print("Velocidad demasiado baja para rebotar:", v.length())
		print("rebotes FINALES: " , bounces_counter)
		return
	else:
		bounces_counter += 1
	# 3) Normal (usa la que te pase el detector si la tienes)
	var n: Vector3 = contact_normal.normalized()
	# 4) Reflejar vector: v_ref = v - 2*(v·n)*n
	var v_reflected: Vector3 = v - 2.0 * v.dot(n) * n
	# 5) Aplicar restitución (pérdida de energía) y añadir boost vertical
	var new_velocity: Vector3 = v_reflected * bounce_restitution
	
	# Aseguramos un empujito extra vertical para darle 'pop' sobre el agua
	# Solo afecta si la componente vertical resultante es pequeña
	if new_velocity.dot(n) < 0.1:
		new_velocity += n * bounce_up_boost
	# 6) Fijar la nueva velocidad directamente
	linear_velocity = new_velocity
	position += n * 0.05


func slow_down_time() -> void:
	Engine.time_scale = 0.3

func normal_speed_time():
	Engine.time_scale = 1.1
	
func speed_up_time():
	Engine.time_scale += 0.1

func reset_stone() -> void:
	is_game_over = false
	power_launch = 20.0
	is_power_selected = false
	is_first_launched = true
	# detener física
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = true
	call_deferred("_apply_initial_transform")
	if aim_ray:
		aim_ray.enabled = true
		aim_ray.show()
	#down_ray.enabled = true
	down_ray.target_position.z = 1
	# restauramos la target_position guardada
	call_deferred("_restore_aim_ray_state")
	freeze = true
	_aim_phase = 0.0
	aim_ray.enabled = true
	aim_ray.show()
	bounces_counter = 0

func _apply_initial_transform() -> void:
	global_transform = initial_transform
	# asegurarnos otra vez de que no tenga velocidades residuales
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = true
	# Si tienes UI o variables de juego, haz el resto del reset aquí,
	# por ejemplo: ocultar mensaje "game over", restablecer contadores, etc.

func _restore_aim_ray_state() -> void:
	if not aim_ray:
		return
	aim_ray.target_position = initial_aim_target
	_aim_phase = 0.0
	# forzamos update del raycast para que su objetivo quede “realizado” este frame
	aim_ray.force_raycast_update()
	# opcional: asegurar visibilidad/enable
	aim_ray.enabled = true
	aim_ray.show()
