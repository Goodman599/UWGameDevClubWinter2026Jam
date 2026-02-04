extends Node2D

@onready var dialogue_box = %DialogueBox
@onready var card_container = $UI/Control/CardPanel/CardContainer
@onready var count_label = $UI/Control/CountLabel
@onready var forget_button = $UI/Control/Button
@onready var background_sprite = $background
@onready var player_sprite = $player_ui

var card_scene = preload("res://Scenes/card_view.tscn")
var cards_to_forget: Array = []
var current_submission_cards: Array = []
var max_memories = 6

#preload arts for changes
var bg_texture_day = preload("res://Assets/day_background.png")
var bg_texture_night = preload("res://Assets/night_background.png")
var player_day = preload("res://Assets/day_player.png")
var player_night = preload("res://Assets/night_player.png")
var dragged_card: Control = null
var drag_start_index: int = -1

func _ready():
	dialogue_box.keyword_clicked.connect(_on_keyword_received)
	
	if forget_button:
		forget_button.pressed.connect(func(): get_node("ForgetScreen").appear())
		
	VisitorManager.time_changed.connect(_update_background)

func _on_keyword_received(key: String):
	if not MemoryManager.add_memory(key):
		return
		
	var data = MemoryDB.get_memory(key)
	
	if data == null: 
		return
	
	var new_card = card_scene.instantiate()
	card_container.add_child(new_card)
	new_card.setup(data)
	
	
	# 2. Drag signals (ONCE!)
	if new_card.has_signal("card_drag_started"):
		new_card.card_drag_started.connect(_start_card_drag)
	
	if new_card.has_signal("card_drag_ended"):
		new_card.card_drag_ended.connect(_end_card_drag)
	
	# 3. Other signals
	if new_card.has_signal("card_dropped_in_area"):
		new_card.card_dropped_in_area.connect(_on_card_dropped_in_area)


#player and backgrounds changes func
func _update_background(is_day : bool):
	if is_day:
		background_sprite.texture = bg_texture_day
		player_sprite.texture = player_day
	else:
		background_sprite.texture = bg_texture_night
		player_sprite.texture = player_night

func _on_card_toggle(card_node, is_selected):
	if is_selected:
		if not card_node in cards_to_forget:
			cards_to_forget.append(card_node)
	else:
		if card_node in cards_to_forget:
			cards_to_forget.erase(card_node)

func _on_forget_pressed():
	if cards_to_forget.is_empty():
		print("I have to forget something")
		return
	
	

func _start_card_drag(card_node):
	dragged_card = card_node
	var cards = card_container.get_children()
	drag_start_index = cards.find(card_node)

func _end_card_drag(card_node):
	print("DRAG ENDED - Card: ", card_node.memory_key)
	
	if not dragged_card:
		return
	
	var mouse_pos = get_global_mouse_position()
	print("Mouse position: ", mouse_pos)
	
	var drop_card = _get_card_at_position()
	
	if drop_card and drop_card != dragged_card:
		print("Found drop card: ", drop_card.memory_key)
		
		# Get current indices
		var cards = card_container.get_children()
		var drag_index = cards.find(dragged_card)   # Current position of dragged card
		var drop_index = cards.find(drop_card)      # Current position of drop card
		
		print("Swapping:")
		print("  Card at index ", drag_index, " (", dragged_card.memory_key, ")")
		print("  with Card at index ", drop_index, " (", drop_card.memory_key, ")")
		
		if drag_index < drop_index:
			# Dragged card is LEFT of drop card
			# Example: swapping [A, B] → [B, A]
			# 1. Move RIGHT card (B) to LEFT position first
			card_container.move_child(drop_card, drag_index)
			# Now: [B, A]
			# 2. Move LEFT card (A) to RIGHT position
			card_container.move_child(dragged_card, drop_index)
			# Final: [B, A] ✓
		else:
			# Dragged card is RIGHT of drop card
			# Example: swapping [B, A] → [A, B]
			# 1. Move LEFT card (A) to RIGHT position first
			card_container.move_child(dragged_card, drop_index)
			# 2. Move RIGHT card (B) to LEFT position
			card_container.move_child(drop_card, drag_index)
		
		print("Swap complete!")
		
		# DEBUG: Check final positions
		var final_cards = card_container.get_children()
		print("Final order:")
		for i in range(final_cards.size()):
			print("  [", i, "] ", final_cards[i].memory_key)
	
	dragged_card = null
	drag_start_index = -1

func _get_card_at_position() -> Control:
	var local_pos = card_container.get_local_mouse_position()
	var CARD_WIDTH = 100
	
	var card_index = int(local_pos.x / CARD_WIDTH)
	var card_count = card_container.get_child_count()
	
	card_index = clampi(card_index, 0, card_count - 1)
	
	if card_count > 0:
		var detected_card = card_container.get_child(card_index)
		return detected_card
	
	return null

func _on_card_drag_started(card_node):
	print("Card drag started: ", card_node.content_label.text)

func _on_card_drag_ended(card_node):
	print("Card drag ended: ", card_node.content_label.text)

func _on_card_dropped_in_area(card_node, area):
	print("Card dropped in area: ", card_node.memory_key)
	print("Area: ", area.name if area else "Unknown")
	
	process_card_submission(card_node, area)

func process_card_submission(card_node, area):
	var memory_data = card_node.get_memory_data() if card_node.has_method("get_memory_data") else {}
	print("Processing submission: ", memory_data)
	
	if area.has_method("process_submission"):
		area.process_submission([memory_data])

func get_submission_areas():
	return get_tree().get_nodes_in_group("submission_area")

func _on_card_stuck(card, box):
	print("Card stuck: ", card.memory_key, " to ", box.name)

func _on_card_unstuck(card, box):
	print("Card removed: ", card.memory_key, " from ", box.name)

func _on_wrong_card_type(card, box):
	print("WRONG TYPE! ", card.get_card_type(), " card in ", box.name)

func _on_submission_complete(cards):
	print("Submission complete with ", cards.size(), " cards")
