extends Node

signal memory_added(key: String)
signal memory_removed(key: String)

var collected_memories: Array[String] = []
var cards_to_forget : Array[MemoryCard] = []
const max_memories = 7

@onready var forget_screen = get_tree().root.get_node("Main/ForgetScreen")
var in_forget_mode := false



func swap_cards(card1 : MemoryCard, card2 : MemoryCard):
	var card_container = get_tree().root.get_node("Main/UI/Control/CardPanel/CardContainer")
	var cards = card_container.get_children()
	var drag_index = cards.find(card1)   # Current position of dragged card
	var drop_index = cards.find(card2)      # Current position of drop card
	
	print("Swapping:")
	print("  Card at index ", drag_index, " (", card1.memory_key, ")")
	print("  with Card at index ", drop_index, " (", card2.memory_key, ")")
	
	if drag_index < drop_index:
		# Dragged card is LEFT of drop card
		# Example: swapping [A, B] → [B, A]
		# 1. Move RIGHT card (B) to LEFT position first
		card_container.move_child(card1, drop_index)
		# Now: [B, A]
		# 2. Move LEFT card (A) to RIGHT position
		card_container.move_child(card2, drag_index)
		# Final: [B, A] ✓
	else:
		# Dragged card is RIGHT of drop card
		# Example: swapping [B, A] → [A, B]
		# 1. Move LEFT card (A) to RIGHT position first
		card_container.move_child(card2, drag_index)
		# 2. Move RIGHT card (B) to LEFT position
		card_container.move_child(card1, drop_index)
	
	
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
