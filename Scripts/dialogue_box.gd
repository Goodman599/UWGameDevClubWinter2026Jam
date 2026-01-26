extends Node2D
class_name DialogueBox

# There will only be one instance of the dialogue box scene in the main scene.
# Visitors will store a reference to this scene
# Contains methods to change the text being shown and detect clicks on keywords

signal keyword_clicked(keyword_text: String)

# Takes a String and puts it into the Text node
func set_text(text : String):
	$Text.text = text


# Called automatically when a keyword is clicked.
# @param meta is the text clicked on, saved as a String
func _on_text_meta_clicked(meta):
	assert (meta is String, "Meta wasn't a string, was: " + meta)
	
	var dictKey : String = meta.capitalize()
	Keywords.keywords[dictKey] += 1
	emit_signal("keyword_clicked", meta)
