extends CanvasLayer
class_name ForgetScreen

@onready var forget_button : TextureButton = $Forget

const BASE_COLOR = Color8(0, 70, 255)
const HOVERED_COLOR = Color8(0, 30, 215)
const PRESSED_COLOR = Color8(0, 0, 185)


func _ready():
	forget_button.self_modulate = BASE_COLOR
	forget_button.button_up.connect(set_color.bind(BASE_COLOR))
	forget_button.button_down.connect(set_color.bind(PRESSED_COLOR))
	forget_button.mouse_exited.connect(set_color.bind(BASE_COLOR))
	forget_button.mouse_entered.connect(set_color.bind(HOVERED_COLOR))
	forget_button.pressed.connect(func(): print("Hi"))

func set_color(color : Color):
	forget_button.self_modulate = color
