extends Node2D
class_name BaseVisitor

# Base visitor class for visitors to extend off of.

# Dialogue is stored per-visitor aka each visitor stores their own dialogue
# Dialogue is stored as a dictionary (not memory efficient but who cares)
#	The keys are the "names of the branch" and the value is an array of dialogues.
var dialogues : Dictionary

# Visitors need a reference to the dialogue box to show their text
@export var dialogue_box : DialogueBox

# Variables to keep track of which dialogue is currently being shown
var current_dialogue_branch : String
var current_dialogue_index : int = 0

# Connect the 2 buttons on the dialogue_box scene to the dialogue managers
func _ready():
	dialogue_box.get_node("Next").pressed.connect(next_dialogue)
	dialogue_box.get_node("Back").pressed.connect(prev_dialogue)


# Takes a String, formats it, and puts it into the dialogue box
func show_text(text : String):
	dialogue_box.set_text(plain_to_clickable(text))
	

# Method that converts "{}" in dialogue to appropriate BBCodes
func plain_to_clickable(text : String) -> String:
	text = text.replace("{", "[b][url]")
	text = text.replace("}", "[/url][/b]")
	return text


# Switch to the next dialogue in the current branch
# TODO: No index out of bounds detections
func next_dialogue():
	current_dialogue_index += 1
	show_text(dialogues[current_dialogue_branch][current_dialogue_index])


# Switch to the previous dialogue in the current branch
# TODO: No index out of bounds detections
func prev_dialogue():
	current_dialogue_index -= 1
	show_text(dialogues[current_dialogue_branch][current_dialogue_index])


