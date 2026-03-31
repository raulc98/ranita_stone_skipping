extends Node

var bounces_record = 0
var distance_record = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_records();

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func save_record(new_bounces, new_distance):
	if new_bounces > bounces_record:
		print("Nuevo record de botes")
		bounces_record = new_bounces
	if new_distance > distance_record:
		print("Nuevo record de botes")
		distance_record = new_distance
	# ABRIR archivo para ESCRIBIR (WRITE)
	var file = FileAccess.open("user://records.dat", FileAccess.WRITE)    
	# Guardar datos
	file.store_32(bounces_record)      # Guarda botes (número entero)
	file.store_32(distance_record)  # Guarda distancia (número con decimales)
	file.close()
	print("Records guardados:", bounces_record, " botes, ", distance_record, " m")

func load_records():
 # Verificar si el archivo EXISTE (solo necesita la ruta)
	if FileAccess.file_exists("user://records.dat"):
		# ABRIR archivo para LEER (READ)
		var file = FileAccess.open("user://records.dat", FileAccess.READ)
		# Leer datos
		bounces_record = file.get_32()
		distance_record = file.get_float()
		file.close()
		print("Records cargados:", bounces_record, " botes, ", distance_record, " m")
	else:
		print("No hay records guardados. Empezando desde cero.")
