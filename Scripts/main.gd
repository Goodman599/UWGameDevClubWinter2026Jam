extends Node2D
class_name Main

@onready var dialogue_box = %DialogueBox
@onready var card_container = $UI/Control/CardPanel/CardContainer
@onready var count_label = $UI/Control/CountLabel
@onready var forget_button = $UI/Control/Button
@onready var background_sprite = $background
@onready var player_sprite = $player_ui

var card_scene = preload("res://Scenes/card_view.tscn")
var dummy_card_scene = preload("res://Scenes/dummy_card.tscn")
var current_submission_cards: Array = []

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
		forget_button.pressed.connect(_on_forget_button_pressed)
		forget_button.mouse_entered.connect(_on_forget_button_hovered)
	
	if forget_button:
		forget_button.pressed.connect(func(): get_node("ForgetScreen").appear())
		
		
	VisitorManager.time_changed.connect(_update_background)
	
	for i in range(MemoryManager.max_memories):
		card_container.add_child(dummy_card_scene.instantiate())

func _on_forget_button_pressed():
	# Play button click sound
	var audio_manager = get_node("/root/Main/AudioManager") as AudioManager
	if audio_manager:
		audio_manager.play_click()
	
	get_node("ForgetScreen").appear()

func _on_forget_button_hovered():
	var audio_manager = get_node("/root/Main/AudioManager") as AudioManager
	if audio_manager:
		audio_manager.play_hover()

func _on_keyword_received(key: String):
	if not MemoryManager.add_memory(key):
		return
		
	var data : MemoryData = MemoryDB.get_memory(key)
	
	if data == null: 
		return
	
	var next_free_index : int
	for memory_card_index in card_container.get_child_count():
		if card_container.get_child(memory_card_index).is_dummy:
			next_free_index = memory_card_index
			card_container.get_child(memory_card_index).queue_free()
			break
	
	
	var new_card = card_scene.instantiate()
	card_container.add_child(new_card)
	new_card.setup(data)
	card_container.move_child(new_card, next_free_index)
	
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



func _on_forget_pressed():
	for card in MemoryManager.cards_to_forget:
		var index = card_container.get_children().find(card)
		
		var dummy_card = dummy_card_scene.instantiate()
		card_container.add_child(dummy_card)
		card_container.move_child(dummy_card, index)
	

func _start_card_drag(card_node):
	dragged_card = card_node
	var cards = card_container.get_children()
	drag_start_index = cards.find(card_node)

func _end_card_drag(card_node):
	print("DRAG ENDED - Card: ", card_node.memory_key)


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
