extends Node

signal memory_added(key: String)
signal memory_removed(key: String)

var collected_memories: Array[String] = []
var cards_to_forget : Array[MemoryCard] = []
const max_memories = 7

@onready var forget_screen = get_tree().root.get_node("Main/ForgetScreen")
var in_forget_mode := false


func _ready():
	print(get_tree().root.get_node("Main/ForgetScreen"))


func add_memory(key: String) -> bool:
	if key in collected_memories:
		print("You've already memorized \"", key, "\".")
		return false
	
	if collected_memories.size() >= max_memories:
		print("Your brain is overwhelmed. Can't memorize more.")
		forget_screen.appear()
		return false
	
	collected_memories.append(key)
	
	memory_added.emit(key)
	return true

func add_card_to_forget(card: MemoryCard):
	if not card in cards_to_forget:
		cards_to_forget.append(card)
		forget_screen.add_card_copy_to_container(card)
		

func remove_memory(key: String):
	if key in collected_memories:
		collected_memories.erase(key)
		print("Something about \"", key, "\"is forgot")
		memory_removed.emit(key)

func get_count() -> int:
	return collected_memories.size()

func forget_cards():
	for card in cards_to_forget:
		remove_memory(card.memory_key)
		card.queue_free()
	cards_to_forget.clear()
