extends Node2D
class_name SubmissionBox

@export var max_cards: int = 1
@export var accepted_card_type: String
@export var highlight_color: Color = Color(0.3, 0.8, 0.3, 0.3)
@export var normal_color: Color = Color(0.2, 0.2, 0.2, 0.2)
@export var wrong_type_color: Color = Color(1, 0.3, 0.3, 0.8)

var cards: Array = []
var stuck_cards: Array = []
var is_highlighted: bool = false

@onready var detection_area = $DetectionArea
@onready var card_container = $CardContainer
@onready var target_text_node: RichTextLabel = $Label

var box_index: int = 0

signal card_added(card: Control, box: SubmissionBox)
signal card_removed(card: Control, box: SubmissionBox)
signal submission_ready(cards: Array)
signal wrong_card_type(card: Control, box: SubmissionBox)

func _ready():
	if detection_area:
		detection_area.mouse_entered.connect(_on_mouse_entered)
		detection_area.mouse_exited.connect(_on_mouse_exited)
	
	$Label.text = accepted_card_type

	update_appearance()
	add_to_group("submission_area")

func initialize(card_type : String, index : int):
	accepted_card_type = card_type
	$Label.text = card_type
	box_index = index

func get_box_index() -> int:
	return box_index

func _on_mouse_entered():
	if not is_highlighted:
		is_highlighted = true
		update_appearance()

func _on_mouse_exited():
	if is_highlighted:
		is_highlighted = false
		update_appearance()

func _input(event):
	if is_highlighted and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			clear_cards()

func update_appearance():
	if is_highlighted:
		if target_text_node:
			target_text_node.modulate = highlight_color
	else:
		if target_text_node:
			target_text_node.modulate = Color(1, 1, 1, 1)

func accepts_card_type(card_type: String) -> bool:
	return card_type == accepted_card_type

func can_accept_card(card_type: String) -> bool:
	return accepts_card_type(card_type) and cards.size() < max_cards

func add_card(card: Control) -> bool:
	var card_type = card.get_card_type() if card.has_method("get_card_type") else ""
	
	if not accepts_card_type(card_type):
		wrong_card_type.emit(card, self)
		show_wrong_type_feedback()
		return false

	if cards.size() >= max_cards:
		return false

	if card.has_method("remove_from_area"):
		card.remove_from_area()

	cards.append(card)

	var card_2d = create_sticky_card(card)
	stuck_cards.append(card_2d)
	card_container.add_child(card_2d)
	position_sticky_card(card_2d, cards.size() - 1)

	if card.has_method("set_stuck_to_box"):
		card.set_stuck_to_box(self)
	
	update_appearance()
	card_added.emit(card, self)

	if cards.size() == max_cards:
		submission_ready.emit(cards)
	
	return true

func remove_card(card: Control):
	var index = cards.find(card)
	if index != -1:
		if index < stuck_cards.size():
			var card_2d = stuck_cards[index]
			card_container.remove_child(card_2d)
			card_2d.queue_free()
			stuck_cards.remove_at(index)
		
		cards.remove_at(index)
		
		if card.has_method("set_stuck_to_box"):
			card.set_stuck_to_box(null)

		reposition_cards()
		
		update_appearance()
		card_removed.emit(card, self)

func create_sticky_card(card: Control) -> Sprite2D:
	var card_2d = Sprite2D.new()
	card_2d.name = "StickyCard_" + card.memory_key

	var image = Image.create(120, 180, false, Image.FORMAT_RGBA8)
	
	var card_color = Color(0.3, 0.3, 0.4)
	if card.has_method("get_card_type"):
		match card.get_card_type():
			"Person":
				card_color = Color("#29abe2") 
			"Event":
				card_color = Color("#22b14c") 
	
	image.fill(card_color)
	card_2d.texture = ImageTexture.create_from_image(image)
	card_2d.scale = Vector2(0.3, 0.3)
	card_2d.z_index = 5

	card_2d.set_meta("ui_card", card)
	card_2d.set_meta("submission_box", self)
	
	return card_2d

func position_sticky_card(card_2d: Sprite2D, index: int):
	if not target_text_node:
		return
	
	var text_pos = target_text_node.global_position
	var text_size = target_text_node.size

	var card_spacing = 80
	var total_width = min(max_cards, cards.size()) * card_spacing
	var start_x = text_pos.x + (text_size.x - total_width) / 2 + card_spacing / 2
	
	var target_x = start_x + index * card_spacing
	var target_y = text_pos.y

	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_2d, "global_position", Vector2(target_x, target_y), 0.4)
	
	var rotation = randf_range(-10, 10)
	tween.parallel().tween_property(card_2d, "rotation_degrees", rotation, 0.3)

func show_wrong_type_feedback():
	if target_text_node:
		var original_modulate = target_text_node.modulate
		var tween = create_tween()
		tween.tween_property(target_text_node, "modulate", wrong_type_color, 0.2)
		tween.tween_property(target_text_node, "modulate", original_modulate, 0.2).set_delay(0.2)

func reposition_cards():
	for i in range(stuck_cards.size()):
		position_sticky_card(stuck_cards[i], i)

func clear_cards():
	for card in cards.duplicate():
		remove_card(card)

func get_card_data():
	for card in cards:
		if card.has_method("get_memory_data"):
			return card.get_memory_data()
	return null

func set_highlight(should_highlight: bool):
	if should_highlight and cards.size() < max_cards:
		is_highlighted = true
	elif not should_highlight:
		is_highlighted = false
	update_appearance()

func get_detection_rect() -> Rect2:
	if detection_area:
		var shape = detection_area.get_child(0) as CollisionShape2D
		if shape:
			var global_pos = detection_area.global_position
			var shape_size = shape.shape.size
			return Rect2(global_pos - shape_size / 2, shape_size)
	return Rect2()
