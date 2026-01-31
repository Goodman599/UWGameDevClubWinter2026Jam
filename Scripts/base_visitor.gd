extends Node2D
class_name BaseVisitor

# Base visitor class for visitors to extend off of.

# Dialogue is stored per-visitor aka each visitor stores their own dialogue
# Dialogue is stored as a dictionary (not memory efficient but who cares)
#	The keys are the "names of the branch" and the value is an array of dialogues.
var dialogues : Dictionary

# Name of the visitor; Used to load dialogue file
@export var visitor_name : String

# Visitors need a reference to the dialogue box to show their text
@export var dialogue_box : DialogueBox

# Variables to keep track of which dialogue is currently being shown
var current_visit_branch : String
var current_dialogue_branch : String
var current_dialogue_index : int = 0
var current_dialogue_line_count : int

func _ready():
	# Connect the 2 buttons on the dialogue_box scene to the dialogue managers
	dialogue_box.get_node("Next").pressed.connect(next_dialogue)
	dialogue_box.get_node("Back").pressed.connect(prev_dialogue)
	
	# Load dialogue from json
	dialogues = load_json_as_dict("res://Dialogues/" + visitor_name + ".json")
	print(dialogues)
	print("res://Dialogues/" + visitor_name + ".json")


# Takes a String, formats it, and puts it into the dialogue box
func show_text(text : String):
	dialogue_box.set_text(plain_to_clickable(text))
	

# Method that converts "{}" in dialogue to appropriate BBCodes
func plain_to_clickable(text : String) -> String:
	text = text.replace("{", "[b][url]")
	text = text.replace("}", "[/url][/b]")
	return text

# Switch to the next dialogue in the current branch
func next_dialogue():
	if current_dialogue_index < current_dialogue_line_count:
		# If just submitted
		if current_dialogue_index == current_dialogue_line_count - 1:
			check_submissions()
			return
		
		current_dialogue_index += 1
		show_text(dialogues[current_visit_branch][current_dialogue_branch]["lines"][current_dialogue_index])
		
		# Show any input boxes
		if current_dialogue_index == current_dialogue_line_count - 1:
			for requirement : String in dialogues[current_visit_branch][current_dialogue_branch]["accepts"]:
				dialogue_box.get_node("Next").text = "Submit"
				create_submission_box(requirement)


# Switch to the previous dialogue in the current branch
func prev_dialogue():
	if current_dialogue_index > 0:
		current_dialogue_index -= 1
		show_text(dialogues[current_visit_branch][current_dialogue_branch]["lines"][current_dialogue_index])
		
		# Exiting out of submission line
		if current_dialogue_index == current_dialogue_line_count - 2:
			dialogue_box.get_node("Next").text = "Next"


# Sets the visit branch to the given string
# Also sets the dialogue branch to dialogue0
func set_visit_branch(branch_name : String) -> void:
	current_visit_branch = branch_name
	set_dialogue_branch("dialogue0")

# Sets the dialogue branch to the given string
# Also initializes the line count
# Also display's the dialogue as text
func set_dialogue_branch(branch_name : String):
	current_dialogue_branch = branch_name
	current_dialogue_line_count = dialogues[current_visit_branch][current_dialogue_branch]["lines"].size()
	show_text(dialogues[current_visit_branch][current_dialogue_branch]["lines"][current_dialogue_index])

# Takes a file path and returns a json as a dictionary
func load_json_as_dict(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: " + path + ". Make sure the name of the visitor is set correctly")
		return {}
	var json_text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_error("JSON parse error: %s at line %d" % [json.get_error_message(), json.get_error_line()])
		return {}
	return json.data


func queue_visit():
	pass

# Goes through every child (Which should only be submission boxes
func check_submissions():
	for child in get_children():
		if child is SubmissionEventBox or child is SubmissionPersonBox:
			print(child.get_card_data())
	

func create_submission_box(type : String):
	var box
	if type == "person":
		box = load("res://Scenes/submission_person_box.tscn")
	elif type == "event":
		box = load("res://Scenes/submission_event_box.tscn")
	add_child(box.instantiate())
