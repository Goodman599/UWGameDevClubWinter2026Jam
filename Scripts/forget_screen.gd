extends CanvasLayer

@onready var forget_button : TextureButton = $Forget

var memory_card = preload("res://Scenes/dummy_card.tscn")

const BASE_COLOR = Color8(0, 70, 255)
const HOVERED_COLOR = Color8(0, 30, 215)
const PRESSED_COLOR = Color8(0, 0, 185)


func _ready():
	disappear()
	
	forget_button.self_modulate = BASE_COLOR
	forget_button.button_up.connect(set_color.bind(BASE_COLOR))
	forget_button.button_down.connect(set_color.bind(PRESSED_COLOR))
	forget_button.mouse_exited.connect(set_color.bind(BASE_COLOR))
	forget_button.mouse_entered.connect(set_color.bind(HOVERED_COLOR))
	forget_button.pressed.connect(confirmed)
	
	forget_button.mouse_entered.connect(_on_forget_button_hovered)

func _on_forget_button_hovered():
	var audio_manager = get_node("/root/Main/AudioManager") as AudioManager
	if audio_manager:
		audio_manager.play_hover()

func set_color(color : Color):
	forget_button.self_modulate = color

func appear():
	MemoryManager.in_forget_mode = true
	show()

func disappear():
	MemoryManager.in_forget_mode = false
	hide()

func confirmed():
	# Play confirm sound
	var audio_manager = get_node("/root/Main/AudioManager") as AudioManager
	if audio_manager:
		audio_manager.play_choice_confirm()
	
	MemoryManager.forget_cards()
	
	for child in $CardContainer.get_children():
		child.queue_free()
	disappear()

func add_card_copy_to_container(card : MemoryCard):
	var new_card = memory_card.instantiate()
	new_card.is_dummy = false
	new_card.can_swap = false
	new_card.is_copy_of_forgotten = true
	$CardContainer.add_child(new_card)
	new_card.copy_attributes(card)
