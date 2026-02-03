extends Node2D
class_name DialogueBox

# There will only be one instance of the dialogue box scene in the main scene.
# Visitors will store a reference to this scene

signal keyword_clicked(keyword_text: String)

@onready var confirm_button = $Confirm  # Assuming you have a Confirm button node
@onready var box_sprite = $Sprite2D   #dialogue_box texture

var texture_normal = preload("res://Assets/dialogue_box.png")
var texture_demon = preload("res://Assets/demon_dialogue_box.png")

func _ready():
	# Hide confirm button initially
	if confirm_button:
		confirm_button.hide()

# Takes a String and puts it into the Text node
func set_text(text : String):
	$Text.text = text

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
