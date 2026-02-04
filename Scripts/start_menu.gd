extends Control
class_name StartMenu

@onready var black_screen = $BlackScreen
# Called when the node enters the scene tree for the first time.

func _on_start_button_pressed():
	black_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	
	tween.tween_property(black_screen, "modulate:a", 1.0, 1.0)
	await tween.finished
	
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
