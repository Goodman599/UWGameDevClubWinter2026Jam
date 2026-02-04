extends Control
class_name MemoryCard

signal card_drag_started(card_node)
signal card_drag_ended(card_node)
signal card_dropped_in_area(card_node, area)

@onready var type_label = $Type
@onready var content_label = $Content
@onready var bg = $Card

const COLOR_PERSON = Color("#29abe2")
const COLOR_EVENT = Color("#22b14c")
const COLOR_FEELING = Color("#a349a4")
const COLOR_ITEM = Color("d36529ff")
const COLOR_ACTION = Color("890029ff")

const BG_COLOR_PERSON = Color("ccecfeff")
const BG_COLOR_EVENT = Color("2ff86cff")
const BG_COLOR_FEELING = Color("db91daff")
const BG_COLOR_ITEM = Color("fcc0a6ff")
const BG_COLOR_ACTION = Color("ff6075ff")

var memory_key: String = ""
var memory_type: int = 0
var is_dragging: bool = false
var is_click_started_on_card: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var original_parent: Control
var original_z_index: int = 0
var original_scale: Vector2 = Vector2.ONE
var drag_threshold: float = 1.0 
var stuck_to_box: Node = null

var is_over_submission_area: bool = false
var current_submission_area: Node2D = null

var default_pos_type: Vector2
var default_pos_content: Vector2
var default_pos_bg: Vector2

var original: MemoryCard
var is_copy_of_forgotten: bool = false

var card_view_texture = preload("res://Assets/card_view.png")

@export var is_dummy: bool = false
@export var can_swap: bool = true

func _ready():
	default_pos_type = type_label.position
	default_pos_content = content_label.position
	if bg:
		default_pos_bg = bg.position
	else:
		push_error("memory_card.gd: Cannot find background node，please check directory of @onready var bg")
	
	mouse_filter = MouseFilter.MOUSE_FILTER_STOP
	
	original_scale = scale

func setup(data:MemoryData):
	memory_key = data.id
	memory_type = data.type
	content_label.text = data.display_text
	var target_color = Color.WHITE
	
	# Reset bg to default (colored background, no texture)
	if bg:
		bg.texture = null  # Clear any previous texture
		bg.show()
		bg.modulate = Color.WHITE  # Reset color
		
	match data.type:
		MemoryData.MemoryType.Person:
			type_label.text = "Person"
			target_color = COLOR_PERSON
			
			if bg:
				# Try to load custom art based on display_name
				var display_name = content_label.text
				
				# Clean up the display name for filename
				var clean_name : String
				match display_name:
					"Nurse":
						clean_name = "nurse"
					"Father Neal":
						clean_name = "cultist"
					"Detective Raede":
						clean_name = "detective"
					"Shadowy Figure":
						clean_name = "demon"
					"Best Friend":
						clean_name = "friend"
					"Mom":
						clean_name = "mom"
					"Mrs. Wren":
						clean_name = "collector"
				
				var art_texture = load("res://Assets/" + clean_name + "_card.png")
				
				if art_texture:
					# Set the custom art texture
					bg.texture = art_texture
					bg.modulate = Color.WHITE  # Show art in original colors
					# Don't hide! We want to show the art
				else:
					# Fallback to colored background if no art found
					print("Warning: No art found for ", display_name)
					bg.texture = card_view_texture
					bg.modulate = BG_COLOR_PERSON
		
		MemoryData.MemoryType.Event:
			type_label.text = "Event"
			target_color = COLOR_EVENT
			if bg:
				bg.texture = card_view_texture  # Ensure no custom art
				bg.modulate = BG_COLOR_EVENT
			
		MemoryData.MemoryType.Feeling:
			type_label.text = "Feeling"
			target_color = COLOR_FEELING
			if bg:
				bg.texture = card_view_texture
				bg.modulate = BG_COLOR_FEELING
			
		MemoryData.MemoryType.Item:
			type_label.text = "Item"
			target_color = COLOR_ITEM
			if bg:
				bg.texture = card_view_texture
				bg.modulate = BG_COLOR_ITEM
			
		MemoryData.MemoryType.Action:
			type_label.text = "Action"
			target_color = COLOR_ACTION
			if bg:
				bg.texture = card_view_texture
				bg.modulate = BG_COLOR_ACTION
			
	type_label.modulate = target_color

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if is_dummy:
			return
		
		if event.pressed:
			is_click_started_on_card = true
			drag_offset = get_local_mouse_position()
			original_position = global_position
			
			if is_copy_of_forgotten:
				MemoryManager.cards_to_forget.erase(original)
				queue_free()
			elif MemoryManager.in_forget_mode:
				MemoryManager.add_card_to_forget(self)
		else:
			if is_click_started_on_card and not is_dragging:
				pass
			
			if is_dragging:
				stop_drag()
			
			is_click_started_on_card = false
			
	elif event is InputEventMouseMotion and is_click_started_on_card and not is_dragging:
		var mouse_move_distance = event.relative.length()
		if mouse_move_distance > drag_threshold:
			start_drag()

# A method to make a card a copy of another card
func copy_attributes(card : MemoryCard) -> void:
	original = card
	
	var memory_data = MemoryData.new()
	memory_data.id = card.memory_key
	memory_data.type = card.memory_type
	memory_data.display_text = card.content_label.text
	setup(memory_data)

func _process(_delta):
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset
		
		check_submission_areas()

func start_drag():
	is_dragging = true
	original_parent = get_parent()
	original_z_index = z_index
	
	var audio_manager = get_node("/root/Main/AudioManager") as AudioManager
	if audio_manager:
		audio_manager.play_pick_up_card()
	
	global_position = original_position
	
	scale = original_scale * 1.2
	modulate = Color(1, 1, 1, 0.8)
	z_index = 100
	
	card_drag_started.emit(self)

func stop_drag():
	if not is_dragging:
		return
	
	is_dragging = false
	
	var audio_manager = get_node("/root/Main/AudioManager") as AudioManager
	if audio_manager:
		audio_manager.play_put_down_card()
	
	if is_over_submission_area and current_submission_area:
		drop_into_area(current_submission_area)
	elif $Hitbox.get_overlapping_areas().size() > 0:
		var swapping = false
		
		var valid_cards : Array[MemoryCard] = []
		for area in $Hitbox.get_overlapping_areas():
			if area.get_parent() is MemoryCard and area.get_parent().can_swap:
				valid_cards.append(area.get_parent())
				
				swapping = true
		
		if !swapping:
			return_to_original()
				
		var smallest_distance : float = abs(self.global_position.x - valid_cards[0].global_position.x)
		var closest_index = 0
		
		for i in range(valid_cards.size()):
			if smallest_distance > abs(self.global_position.x - valid_cards[i].global_position.x):
				smallest_distance = abs(self.global_position.x - valid_cards[i].global_position.x)
				closest_index = i
		
		MemoryManager.swap_cards(self, valid_cards[closest_index])
		
	else:
		return_to_original()
	
	scale = original_scale
	modulate = Color(1, 1, 1, 1)
	z_index = original_z_index

	is_over_submission_area = false
	current_submission_area = null
	
	card_drag_ended.emit(self)




# In memory_card.gd, modify check_submission_areas():
func check_submission_areas():
	var submission_areas = get_tree().get_nodes_in_group("submission_area")
	
	var mouse_pos = get_global_mouse_position()
	
	var found_area = false
	
	for area in submission_areas:
		if area.has_method("get_detection_rect"):
			var area_rect = area.get_detection_rect()
			if area_rect.has_point(mouse_pos):
				is_over_submission_area = true
				current_submission_area = area
				found_area = true
				break
		elif area is Control:
			var area_rect = Rect2(area.global_position, area.size)
			if area_rect.has_point(mouse_pos):
				is_over_submission_area = true
				current_submission_area = area
				found_area = true
				break

	if not found_area:
		is_over_submission_area = false
		current_submission_area = null

func drop_into_area(area: Node2D):
	if not area:
		return_to_original()
		return

	if area.has_method("accepts_card_type"):
		var card_type = get_card_type()
		if not area.accepts_card_type(card_type):
			show_wrong_type_feedback()
			return_to_original()
			return

	if area.has_method("add_card"):
		var success = area.add_card(self)
		if success:
			stuck_to_box = area
			card_dropped_in_area.emit(self, area)
			return
		else:
			return_to_original()
			return
	
	return_to_original()

func return_to_original():
	if original_parent and original_parent != get_parent():
		if get_parent():
			get_parent().remove_child(self)
		
		original_parent.add_child(self)
	
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", original_position, 0.3)

func get_memory_data() -> Dictionary:
	return {
		"key": memory_key,
		"type": type_label.text,
		"content": content_label.text,
		"node": self
	}

func remove_from_area():
	if current_submission_area:
		current_submission_area = null
		is_over_submission_area = false
		
	if stuck_to_box and stuck_to_box.has_method("remove_card"):
		stuck_to_box.remove_card(self)
	
	return_to_original()

func _on_mouse_entered():
	if not is_dragging:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", original_scale * 1.05, 0.1)

func _on_mouse_exited():
	if not is_dragging:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", original_scale, 0.1)

func get_card_type() -> String:
	return type_label.text 

func set_stuck_to_box(box: Node):
	stuck_to_box = box
	
	if box:
		is_dragging = false

		modulate = Color(1, 1, 1, 0.5)
	else:
		modulate = Color(1, 1, 1, 1)

func show_wrong_type_feedback():
	var original_pos = global_position
	var tween = create_tween()
	for i in range(2):
		tween.tween_property(self, "global_position", original_pos + Vector2(10, 0), 0.05)
		tween.tween_property(self, "global_position", original_pos + Vector2(-10, 0), 0.05)
	tween.tween_property(self, "global_position", original_pos, 0.05)
