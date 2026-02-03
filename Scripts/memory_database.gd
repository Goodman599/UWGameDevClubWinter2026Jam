extends Node

var database : Dictionary = {}


func _register(key: String, type: int, display_text: String = ""):
	if database.has(key.to_lower()):
		print("MemoryDB: Entry " + key + " already exists")
		return
	
	var data = MemoryData.new()
	data.id = key
	data.type = type
	data.display_text = display_text
	database[key.to_lower()] = data

func get_memory(key: String) -> MemoryData:
	return database.get(key.to_lower())
