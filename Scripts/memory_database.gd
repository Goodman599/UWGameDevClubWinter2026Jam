extends Node

var database : Dictionary = {}

func _ready() -> void:
	_register("Jimmy Jones", MemoryData.MemoryType.Person)
	_register("car crash", MemoryData.MemoryType.Event, "Car Accident")
	_register("disgust", MemoryData.MemoryType.Feeling, "Disgust")

func _register(key: String, type: int, display_text: String = ""):
	var data = MemoryData.new()
	data.id = key
	data.type = type
	data.display_text = display_text if display_text != "" else key
	database[key.to_lower()] = data

func get_memory(key: String) -> MemoryData:
	return database.get(key.to_lower())
