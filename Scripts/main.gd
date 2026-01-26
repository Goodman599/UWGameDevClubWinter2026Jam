extends Node2D

@onready var dialogue_box = %DialogueBox
@onready var card_container = $UI/Control/CardPanel/CardContainer
@onready var count_label = $UI/Control/CountLabel
@onready var forget_button = $UI/Control/Button

#const max_cards = 6
#var collected_cards : Array[String] = []
var card_scene = preload("res://Scenes/card_view.tscn")
var cards_to_forget: Array = []

func _ready():
	dialogue_box.keyword_clicked.connect(_on_keyword_received)
	
	if forget_button:
		forget_button.pressed.connect(_on_forget_pressed)

func _on_keyword_received(key: String):
	if not MemoryManager.add_memory(key):
		return
		
	var data = MemoryDB.get_memory(key)
	if data == null: 
		return
	
	var new_card = card_scene.instantiate()
	card_container.add_child(new_card)
	new_card.setup(data)
	
	new_card.selection_toggled.connect(_on_card_toggle)
	
	update_ui_text()
	
	#Below is the code for main.gd to manage those memory cards
	#if key in collected_cards:
		#return
	#
	#if collected_cards.size() >= max_cards:
		#return
	#var data = MemoryDB.get_memory(key)
	#if data == null:
		#return
	#
	#var new_card = card_scene.instantiate()
	#card_container.add_child(new_card)
	#
	#new_card.setup(data)
	#collected_cards.append(key)
	#update_ui_text()

func update_ui_text():
	if count_label:
		var count = MemoryManager.get_count()
		var max_count = MemoryManager.max_memories
		count_label.text = "Memories: %s/%s" % [count, max_count]

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
