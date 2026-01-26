extends Control

signal selection_toggled(card_node, is_selected)

@onready var type_label = $Type
@onready var content_label = $Content
@onready var bg = $Card

const COLOR_PERSON = Color("#29abe2")
const COLOR_EVENT = Color("#22b14c")
const COLOR_FEELING = Color("#a349a4")

var memory_key: String = ""
var is_selected: bool = false

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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		toggle_selection()

func toggle_selection():
	is_selected = not is_selected
	selection_toggled.emit(self, is_selected)
	
	#These are codes for selection animation
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var offset = Vector2(0, -15) if is_selected else Vector2.ZERO
	
	
	tween.tween_property(type_label, "position", default_pos_type + offset, 0.2)
	tween.tween_property(content_label, "position", default_pos_content + offset, 0.2)
	if bg:
		tween.tween_property(bg, "position", default_pos_bg + offset, 0.2)
		
	var target_modulate = Color(0.6, 0.6, 0.6) if is_selected else Color(1, 1, 1)
	tween.tween_property(self, "modulate", target_modulate, 0.2)
