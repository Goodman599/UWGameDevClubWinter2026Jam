extends Node2D

@onready var dialogue_box = %DialogueBox
@onready var card_container = $UI/Control/CardPanel/CardContainer
@onready var count_label = $UI/Control/CountLabel
@onready var forget_button = $UI/Control/Button

var card_scene = preload("res://Scenes/card_view.tscn")
var cards_to_forget: Array = []
var current_submission_cards: Array = []
var max_memories = 6

func _ready():
	dialogue_box.keyword_clicked.connect(_on_keyword_received)
	
	if forget_button:
		forget_button.hide()
		forget_button.pressed.connect(_on_forget_pressed)
		
	var person_box = get_node("Submission Box")
	var event_box = get_node("Submission Box2")
	
	for box in [person_box, event_box]:
		if box:
			box.card_added.connect(_on_card_stuck)
			box.card_removed.connect(_on_card_unstuck)
			box.wrong_card_type.connect(_on_wrong_card_type)
			box.submission_ready.connect(_on_submission_complete)

func _on_keyword_received(key: String):
	if not MemoryManager.add_memory(key):
		return
		
	var data = MemoryDB.get_memory(key)
	print(data.type)
	if data == null: 
		return
	
	var new_card = card_scene.instantiate()
	card_container.add_child(new_card)
	new_card.setup(data)
	
	new_card.selection_toggled.connect(_on_card_toggle)
	
	if new_card.has_signal("card_drag_started"):
		new_card.card_drag_started.connect(_on_card_drag_started)
	
	if new_card.has_signal("card_drag_ended"):
		new_card.card_drag_ended.connect(_on_card_drag_ended)
	
	if new_card.has_signal("card_dropped_in_area"):
		new_card.card_dropped_in_area.connect(_on_card_dropped_in_area)
	
	update_ui_text()
	update_forget_button_visibility()

func update_ui_text():
	if count_label:
		var count = MemoryManager.get_count()
		var max_count = MemoryManager.max_memories
		count_label.text = "Memories: %s/%s" % [count, max_count]
		
func update_forget_button_visibility():
	if forget_button:
		var card_count = MemoryManager.get_count()
		if card_count > max_memories:
			forget_button.show()
		else:
			forget_button.hide()

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
	
	for card in cards_to_forget:
		MemoryManager.remove_memory(card.memory_key)
		card.queue_free()
	cards_to_forget.clear()
	
	update_ui_text()
	update_forget_button_visibility()


func _on_card_drag_started(card_node):
	print("Card drag started: ", card_node.memory_key)

func _on_card_drag_ended(card_node):
	print("Card drag ended: ", card_node.memory_key)

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
	update_forget_button_visibility()

func _on_card_unstuck(card, box):
	print("Card removed: ", card.memory_key, " from ", box.name)
	update_forget_button_visibility()

func _on_wrong_card_type(card, box):
	print("WRONG TYPE! ", card.get_card_type(), " card in ", box.name)

func _on_submission_complete(cards):
	print("Submission complete with ", cards.size(), " cards")
