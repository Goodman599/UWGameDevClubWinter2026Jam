extends Control

signal selection_toggled(card_node, is_selected)
signal card_drag_started(card_node)
signal card_drag_ended(card_node)
signal card_dropped_in_area(card_node, area)

@onready var type_label = $Type
@onready var content_label = $Content
@onready var bg = $Card

const COLOR_PERSON = Color("#29abe2")
const COLOR_EVENT = Color("#22b14c")
const COLOR_FEELING = Color("#a349a4")

var memory_key: String = ""
var is_selected: bool = false
var is_dragging: bool = false
var is_click_started_on_card: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var original_parent: Control
var original_z_index: int = 0
var original_scale: Vector2 = Vector2.ONE
var drag_threshold: float = 10.0 
var stuck_to_box: Node = null

var is_over_submission_area: bool = false
var current_submission_area: Node2D = null

var default_pos_type: Vector2
var default_pos_content: Vector2
var default_pos_bg: Vector2

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
	content_label.text = data.display_text
	var target_color = Color.WHITE
	
	match data.type:
		MemoryData.MemoryType.Person:
			type_label.text = "Person"
			target_color = COLOR_PERSON
		
		MemoryData.MemoryType.Event:
			type_label.text = "Event"
			target_color = COLOR_EVENT
			
		MemoryData.MemoryType.Feeling:
			type_label.text = "Feeling"
			target_color = COLOR_FEELING
			
	type_label.modulate = target_color

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_click_started_on_card = true
			drag_offset = get_local_mouse_position()
			original_position = global_position
			
			toggle_selection()
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

func _process(_delta):
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset
		
		check_submission_areas()

func start_drag():
	if  not is_selected:
		return
	
	is_dragging = true
	original_parent = get_parent()
	original_z_index = z_index
	
	get_tree().root.add_child(self)
	global_position = original_position
	
	scale = original_scale * 1.2
	modulate = Color(1, 1, 1, 0.8)
	z_index = 100
	
	card_drag_started.emit(self)

func stop_drag():
	if not is_dragging:
		return
	
	is_dragging = false
	
	if is_over_submission_area and current_submission_area:
		drop_into_area(current_submission_area)
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

func toggle_selection():
	if is_dragging or current_submission_area:
		return
	
	is_selected = not is_selected
	selection_toggled.emit(self, is_selected)

	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var offset = Vector2(0, -15) if is_selected else Vector2.ZERO
	
	tween.tween_property(type_label, "position", default_pos_type + offset, 0.2)
	tween.tween_property(content_label, "position", default_pos_content + offset, 0.2)
	if bg:
		tween.tween_property(bg, "position", default_pos_bg + offset, 0.2)
		
	var target_modulate = Color(0.6, 0.6, 0.6) if is_selected else Color(1, 1, 1)
	tween.tween_property(self, "modulate", target_modulate, 0.2)
	
	var target_scale = Vector2(1.05, 1.05) if is_selected else Vector2.ONE
	tween.tween_property(self, "scale", target_scale, 0.2)

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
	if not is_dragging and not is_selected:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", original_scale, 0.1)

func get_card_type() -> String:
	return type_label.text 

func set_stuck_to_box(box: Node):
	stuck_to_box = box
	
	if box:
		is_dragging = false
		is_selected = false

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
