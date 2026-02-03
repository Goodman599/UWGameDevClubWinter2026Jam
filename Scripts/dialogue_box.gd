extends Node2D
class_name DialogueBox

# There will only be one instance of the dialogue box scene in the main scene.
# Visitors will store a reference to this scene

signal keyword_clicked(keyword_text: String)

@onready var confirm_button = $Confirm  # Assuming you have a Confirm button node

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
