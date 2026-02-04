extends Node

signal memory_removed(key: String)

var collected_memories: Array[String] = []
var cards_to_forget : Array[MemoryCard] = []
const max_memories = 7

var forget_screen : CanvasLayer
var card_container : HBoxContainer

var in_forget_mode := false

func _ready():
	for i in range(max_memories):
		collected_memories.append("")
	

func set_references(card_container_ref, forget_screen_ref):
	card_container = card_container_ref
	forget_screen = forget_screen_ref

func swap_cards(card1 : MemoryCard, card2 : MemoryCard):
	if !card_container:
		return
	
	var cards = card_container.get_children()
	var drag_index = cards.find(card1)   # Current position of dragged card
	var drop_index = cards.find(card2)      # Current position of drop card
	
	#print("Swapping:")
	#print("  Card at index ", drag_index, " (", card1.memory_key, ")")
	#print("  with Card at index ", drop_index, " (", card2.memory_key, ")")
	
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
	
	var temp = collected_memories[drag_index]
	collected_memories[drag_index] = collected_memories[drop_index]
	collected_memories[drop_index] = temp



func add_memory(key: String) -> bool:
	var memory_data : MemoryData = MemoryDB.database.get(key.to_lower())
	if !memory_data:
		print(key, " is not in the database!")
		print("The database is: ", MemoryDB.database)
		return false
		
	var content : String = memory_data.display_text
	
	if content in collected_memories:
		print("You've already memorized \"", content, "\".")
		return false
	
	var next_free_index = -1
	for i in range(max_memories):
		if collected_memories[i] == "":
			next_free_index = i
			break
	
	if next_free_index == -1:
		print("Your brain is overwhelmed. Can't memorize more.")
		forget_screen.appear()
		return false
	
	collected_memories[next_free_index] = content
	
	print(collected_memories)
	return true

func add_card_to_forget(card: MemoryCard):
	if not card in cards_to_forget:
		cards_to_forget.append(card)
		forget_screen.add_card_copy_to_container(card)
		

func remove_memory(key: String):
	if key in collected_memories:
		collected_memories[collected_memories.find(key)] = ""
		print("Something about \"", key, "\"is forgot")
		memory_removed.emit(key)

func get_count() -> int:
	return collected_memories.size()

func forget_cards():
	get_node("../Main")._on_forget_pressed()
	for card : MemoryCard in cards_to_forget:
		remove_memory(card.content_label.text)
		card.queue_free()
	cards_to_forget.clear()
