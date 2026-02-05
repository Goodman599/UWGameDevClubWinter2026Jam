extends Node2D
class_name DialogueBox

# There will only be one instance of the dialogue box scene in the main scene.
# Visitors will store a reference to this scene

signal keyword_clicked(keyword_text: String)
signal scroll_finished

@onready var confirm_button = $Confirm  # Assuming you have a Confirm button node
@onready var box_sprite = $Sprite2D   #dialogue_box texture

var texture_normal = preload("res://Assets/dialogue_box.png")
var texture_demon = preload("res://Assets/demon_dialogue_box.png")

var tween : Tween
var scrolling := false

func _ready():
	# Hide confirm button initially
	if confirm_button:
		confirm_button.hide()
		
	$Next.pressed.connect(_on_next_pressed)
	$Back.pressed.connect(_on_back_pressed)
	$Confirm.pressed.connect(_on_confirm_pressed)
	
	$Next.mouse_entered.connect(_on_button_hovered)
	$Back.mouse_entered.connect(_on_button_hovered)
	$Confirm.mouse_entered.connect(_on_button_hovered)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if scrolling:
				tween.kill()
				scrolling = false
				$Text.visible_ratio = 1
				emit_signal("scroll_finished")

func _on_next_pressed():
	var audio_manager = get_node("/root/Main/AudioManager") as AudioManager
	if audio_manager:
		audio_manager.play_click()

func _on_back_pressed():
	var audio_manager = get_node("/root/Main/AudioManager") as AudioManager
	if audio_manager:
		audio_manager.play_click()

func _on_confirm_pressed():
	var audio_manager = get_node("/root/Main/AudioManager") as AudioManager
	if audio_manager:
		audio_manager.play_choice_confirm()

func _on_button_hovered():
	var audio_manager = get_node("/root/Main/AudioManager") as AudioManager
	if audio_manager:
		audio_manager.play_hover()

# Takes a String and puts it into the Text node
func set_text(text : String):
	check_for_tutorials(text)
	
	$Text.text = text
	$Text.visible_characters = -1

#func _play_dialogue_sound_for_current_visitor():
	#var audio_manager = get_node("/root/Main/AudioManager") as AudioManager
	#var visitor_name = VisitorManager.current_visitor_name if VisitorManager else ""
	#
	#if audio_manager and visitor_name:
		#audio_manager.play_dialogue_sound(visitor_name)


func set_text_scroll(text : String):
	scrolling = true
	check_for_tutorials(text)
	
	$Text.visible_characters = 0
	$Text.text = text
	
	tween = get_tree().create_tween()
	
	# Save some time if text is super long. Scrolling will never take more than 3 seconds
	if text.length() <= 120:
		tween.tween_property($Text, "visible_characters", text.length(), text.length() / 40.0)
	else:
		tween.tween_property($Text, "visible_ratio", 1, 3)
	
	await get_tree().process_frame
	
	# ADD DIALOGUE SOUNDS HERE
	var audio_manager = get_node("/root/Main/AudioManager") as AudioManager
	var visitor_name = VisitorManager.current_visitor_name if VisitorManager else "" 
	
	if audio_manager and visitor_name != "Demon" and visitor_name != "":
		var scroll_time = text.length() / 40.0 if text.length() <= 120 else 3
		var blip_interval = 0.08
		var total_blips = int(scroll_time / blip_interval)
		
		play_blips(total_blips, blip_interval, visitor_name)
			
	else:
		audio_manager.play_dialogue_sound("Demon")
	
	await tween.finished
	
	scrolling = false
	emit_signal("scroll_finished")

func play_blips(blip_count : int, blip_interval : float, visitor_name : String):
	if blip_count == 0 or !scrolling:
		return
	await get_tree().create_timer(blip_interval).timeout
	get_node("/root/Main/AudioManager").play_dialogue_sound(visitor_name)
	play_blips(blip_count - 1, blip_interval, visitor_name)
	


func check_for_tutorials(text : String):
	if text.begins_with("What I am about to say, I say with full sympathy. You’ve been diagnosed with LIS,"):
		$"../Tutorials/TutorialBox".show()
		$"../Tutorials/TutorialBox3".show()
	else:
		$"../Tutorials/TutorialBox".hide()
		$"../Tutorials/TutorialBox3".hide()
	if text.begins_with("I need you to please blink twice if you can hear me."):
		$"../Tutorials/TutorialBox2".show()
	else:
		$"../Tutorials/TutorialBox2".hide()


# Show the confirm button
func show_confirm():
	if confirm_button:
		confirm_button.show()

# Hide the confirm button
func hide_confirm():
	if confirm_button:
		confirm_button.hide()

# Called automatically when a keyword is clicked.
# @param meta is the text clicked on, saved as a String
func _on_text_meta_clicked(meta):
	assert (meta is String, "Meta wasn't a string, was: " + meta)
	
	emit_signal("keyword_clicked", meta)

func switch_style(visitor_name : String):
	if not box_sprite:
		return
	
	var target_texture = texture_normal
	
	if visitor_name == "Demon":
		target_texture = texture_demon
	
	if box_sprite.texture == target_texture:
		return

	var tween = create_tween()
	
	tween.tween_property(box_sprite, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func():
		box_sprite.texture = target_texture)
	
	tween.tween_property(box_sprite, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
