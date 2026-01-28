extends Node

signal memory_added(key: String)
signal memory_removed(key: String)

var collected_memories: Array[String] = []
const max_memories = 6

func add_memory(key: String) -> bool:
	if key in collected_memories:
		print("You've already memorized \"", key, "\".")
		return false
	
	if collected_memories.size() >= max_memories:
		print("Your brain is overwhelmed. Can't memorize more.")
		return false
	
	collected_memories.append(key)
	
	memory_added.emit(key)
	return true

func remove_memory(key: String):
	if key in collected_memories:
		collected_memories.erase(key)
		print("Something about \"", key, "\"is forgot")
		memory_removed.emit(key)

func get_count() -> int:
	return collected_memories.size()
