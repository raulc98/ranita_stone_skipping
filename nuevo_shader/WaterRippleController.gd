## WaterRippleController.gd
## Adjunta este script al MeshInstance3D que tiene el shader de agua.
## Se encarga de gestionar hasta MAX_RIPPLES ondas simultáneas.
##
## USO:
##   water_node.spawn_ripple(hit_position_3d, strength)
##
## El nodo escucha señales de RigidBody3D que caigan sobre él si lo configuras,
## o puedes llamar spawn_ripple() desde cualquier otro script.

extends MeshInstance3D

# ── Configuración ────────────────────────────────────────────────────────────
const MAX_RIPPLES := 8

## Duración en segundos que debe coincidir con ripple_duration del shader
@export var ripple_duration : float = 2.5

# ── Estado interno ───────────────────────────────────────────────────────────
var _pos      : Array[Vector2] = []   # UV del impacto
var _time     : Array[float]   = []   # tiempo transcurrido (-1 = inactivo)
var _strength : Array[float]   = []   # intensidad 0-1

# Referencia al material (se cachea para no buscarlo cada frame)
var _mat : ShaderMaterial

# ── Inicialización ───────────────────────────────────────────────────────────
func _ready() -> void:
	_mat = get_active_material(0) as ShaderMaterial
	assert(_mat != null, "WaterRippleController: el material debe ser un ShaderMaterial.")

	# Rellenamos los arrays con valores inactivos
	for i in MAX_RIPPLES:
		_pos.append(Vector2.ZERO)
		_time.append(-1.0)
		_strength.append(0.0)

	_push_to_shader()

# ── Cada frame ───────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	var dirty := false

	for i in MAX_RIPPLES:
		if _time[i] < 0.0:
			continue
		_time[i] += delta
		if _time[i] >= ripple_duration:
			# Onda caducada → desactivar
			_time[i]     = -1.0
			_strength[i] = 0.0
		dirty = true

	if dirty:
		_push_to_shader()

# ── API pública ───────────────────────────────────────────────────────────────

## Lanza una onda en la posición 3D del impacto.
## hit_pos debe estar en el espacio local del mesh (o en world si usas world_uv).
## strength: 0.0 - 1.0
func spawn_ripple(hit_pos_world: Vector3, strength: float = 1.0) -> void:
	# Convertimos la posición 3D a UV (asumimos plano XZ normalizado al tamaño del mesh)
	var local_pos : Vector3 = to_local(hit_pos_world)
	var mesh_aabb : AABB    = get_aabb()

	var uv := Vector2(
		(local_pos.x - mesh_aabb.position.x) / mesh_aabb.size.x,
		(local_pos.z - mesh_aabb.position.z) / mesh_aabb.size.z
	)
	uv = uv.clamp(Vector2.ZERO, Vector2.ONE)

	var slot := _find_slot()
	_pos[slot]      = uv
	_time[slot]     = 0.0
	_strength[slot] = clamp(strength, 0.0, 1.0)

	_push_to_shader()

# ── Señal de colisión automática ─────────────────────────────────────────────
## Conecta la señal body_entered del Area3D que cubre el agua a este método.
## El Area3D debe tener CollisionShape3D con la misma forma que el agua.
func _on_area_body_entered(body: Node3D) -> void:
	# Intentamos obtener la posición del cuerpo que cayó
	spawn_ripple(body.global_position, 1.0)

# ── Privados ──────────────────────────────────────────────────────────────────
func _find_slot() -> int:
	# Buscamos un slot inactivo
	for i in MAX_RIPPLES:
		if _time[i] < 0.0:
			return i
	# Si todos están ocupados, reciclamos el más antiguo
	var oldest_i    := 0
	var oldest_time := 0.0
	for i in MAX_RIPPLES:
		if _time[i] > oldest_time:
			oldest_time = _time[i]
			oldest_i    = i
	return oldest_i

func _push_to_shader() -> void:
	# Godot 4 pasa arrays de uniforms como PackedVector2Array / PackedFloat32Array
	var pos_arr  := PackedVector2Array(_pos)
	var time_arr := PackedFloat32Array(_time)
	var str_arr  := PackedFloat32Array(_strength)

	_mat.set_shader_parameter("ripple_pos",      pos_arr)
	_mat.set_shader_parameter("ripple_time",     time_arr)
	_mat.set_shader_parameter("ripple_strength", str_arr)
