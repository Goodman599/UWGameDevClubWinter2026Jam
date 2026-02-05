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
@onready var dialogue_box : DialogueBox = get_node("%DialogueBox")

# Visitors need a sprite to show the character sprites
@onready var character_sprite : Sprite2D = $CharacterSprite
var can_submit := true
var takes_inputs := true

# Variables to keep track of which dialogue is currently being shown
var current_visit_branch : String
var current_dialogue_branch : String
var current_dialogue_index : int = 0
var current_dialogue_line_count : int
var max_shown_line_index : int = 0

var current_dialogue_takes_cards := false

var box_scene = preload("res://Scenes/submission_box.tscn")
var instantiated_submission_box_count : int = 0
const SUBMISSION_BOX_POSITIONS = [Vector2(670, 148), Vector2(670, 299)]

# Dictionary to store various visitor states. An example state could be "ritual stage"
var visitor_states := {}

# Store which ending will be shown after the current dialogue.
var endingID := ""

#constant used to make sprites fit the screen
const TARGET_SCREEN_HEIGHT_RATIO = 0.85
const SCREEN_HEIGHT = 648.0
const CHAR_POSITION_X = 900.0
const CHAR_POSITION_Y = 300.0


const SCROLL_ENABLED := true



func _ready():
	# Connect the 2 buttons on the dialogue_box scene to the dialogue managers
	dialogue_box.get_node("Next").pressed.connect(next_dialogue)
	dialogue_box.get_node("Back").pressed.connect(prev_dialogue)
	
	# Connect the confirm button to check cards
	dialogue_box.get_node("Confirm").pressed.connect(dialogue_concluded)
	
	# Load dialogue from json
	dialogues = load_json_as_dict("res://Dialogues/" + visitor_name + ".json")
	
	load_character_sprite()


# Takes a String, formats it, and puts it into the dialogue box
func show_text(text : String, scroll : bool = false):
	if scroll and SCROLL_ENABLED:
		takes_inputs = false
		dialogue_box.set_text_scroll(plain_to_clickable(text))
		
		await dialogue_box.scroll_finished
		takes_inputs = true
		
	else:
		dialogue_box.set_text(plain_to_clickable(text))
	

# Method that converts "{}" in dialogue to appropriate BBCodes
func plain_to_clickable(text : String) -> String:
	# remove keyword data []
	var regex := RegEx.new()
	regex.compile("\\[[^\\]]*\\]")
	text = regex.sub(text, "", true)
	
	# highlight keywords {}
	text = text.replace("{", "[b][url]")
	text = text.replace("}", "[/url][/b]")
	
	text = text.replace("<", "[i]")
	text = text.replace(">", "[/i]")
	
	return text

# Switch to the next dialogue in the current branch
func next_dialogue():
	if VisitorManager.current_visitor_name != visitor_name:
		return
	
	if not takes_inputs:
		return
	
	if current_dialogue_index < current_dialogue_line_count - 1:
		current_dialogue_index += 1
		
		if current_dialogue_index > max_shown_line_index:
			max_shown_line_index = current_dialogue_index
			show_text(dialogues[current_visit_branch][current_dialogue_branch]["lines"][current_dialogue_index], true)
		else:
			show_text(dialogues[current_visit_branch][current_dialogue_branch]["lines"][current_dialogue_index])
		
		if current_dialogue_index == current_dialogue_line_count - 1:
			show_inputs()
		
		dialogue_index_changed()


# Switch to the previous dialogue in the current branch
func prev_dialogue():
	if VisitorManager.current_visitor_name != visitor_name:
		return
	
	if not takes_inputs:
		return
	
	if current_dialogue_index > 0:
		current_dialogue_index -= 1
		show_text(dialogues[current_visit_branch][current_dialogue_branch]["lines"][current_dialogue_index])
		
		# Hide confirm button if not at the end
		if current_dialogue_index < current_dialogue_line_count - 1:
			hide_inputs()
		
		dialogue_index_changed()

# Shows/Hides the next/prev buttons
func dialogue_index_changed():
	if current_dialogue_index == 0:
		dialogue_box.get_node("Back").hide()
	else:
		dialogue_box.get_node("Back").show()
	if current_dialogue_index == current_dialogue_line_count - 1:
		dialogue_box.get_node("Next").hide()
	else:
		dialogue_box.get_node("Next").show()

func show_inputs():
	dialogue_box.show_confirm()
	for child in get_children():
		if child is SubmissionBox:
			child.show()


func hide_inputs():
	dialogue_box.hide_confirm()
	for child in get_children():
		if child is SubmissionBox:
			child.clear_cards()
			child.hide()


# Sets the visit branch to the given string
# Also sets the dialogue branch to dialogue0
func set_visit_branch(branch_name : String) -> void:
	#dialogue_box change to demon style
	if dialogue_box.has_method("switch_style"):
		dialogue_box.switch_style(visitor_name)
	
	current_visit_branch = branch_name
	set_dialogue_branch("dialogue0")
	
	#animation of character sprite changes
	if has_node("CharacterSprite"):
		var sprite = $CharacterSprite
		sprite.visible = true
		sprite.modulate.a = 0.0
		dialogue_box.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(dialogue_box, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# Sets the dialogue branch to the given string
# Also initializes the line count
# Also display's the dialogue as text
# Also adds the keywords to the memory database
func set_dialogue_branch(branch_name : String):
	current_dialogue_branch = branch_name
	current_dialogue_index = 0
	max_shown_line_index = 0
	current_dialogue_line_count = dialogues[current_visit_branch][current_dialogue_branch]["lines"].size()
	show_text(dialogues[current_visit_branch][current_dialogue_branch]["lines"][current_dialogue_index], true)
	register_keywords(dialogues[current_visit_branch][current_dialogue_branch]["lines"])
	
	dialogue_index_changed()
	
	instantiated_submission_box_count = 0
	delete_submission_boxes()
	current_dialogue_takes_cards = false
	
	# If the dialogue leads to an ending:
	if dialogues[current_visit_branch][current_dialogue_branch].has("ending"):
		endingID = dialogues[current_visit_branch][current_dialogue_branch]["ending"]
	# The new dialogue is a submission dialogue line
	elif dialogues[current_visit_branch][current_dialogue_branch].has("accepts"):
		current_dialogue_takes_cards = true
		for requirement : String in dialogues[current_visit_branch][current_dialogue_branch]["accepts"]:
			create_submission_box(requirement)
	# The new dialogue is a redirect dialogue line
	elif dialogues[current_visit_branch][current_dialogue_branch].has("nextVisit"):
		if dialogues[current_visit_branch][current_dialogue_branch]["nextVisit"].has("priority"):
			queue_visit(dialogues[current_visit_branch][current_dialogue_branch]["nextVisit"]["id"], str_to_var(dialogues[current_visit_branch][current_dialogue_branch]["nextVisit"]["delay"]), str_to_var(dialogues[current_visit_branch][current_dialogue_branch]["nextVisit"]["priority"]))
		else:
			queue_visit(dialogues[current_visit_branch][current_dialogue_branch]["nextVisit"]["id"], str_to_var(dialogues[current_visit_branch][current_dialogue_branch]["nextVisit"]["delay"]))
			
	
	if current_dialogue_line_count == 1:
		show_inputs()
	else:
		hide_inputs()

# Register keywords into the database.
func register_keywords(dialogue_array : Array):
	var memory_key : String
	var memory_type : int
	var display_name : String
	
	for line in dialogue_array:
		var search_index = 0
		var next_keyword_occurence_index : int = line.find("{", search_index)
		while next_keyword_occurence_index != -1:
			var next_keyword_end_index : int = line.find("}", search_index)
			memory_key = line.substr(next_keyword_occurence_index + 1, next_keyword_end_index - next_keyword_occurence_index - 1)
			
			# Find the end of the specification
			var memory_data_end_index : int = line.find("]", search_index)
			var memory_data = line.substr(next_keyword_end_index + 1, memory_data_end_index - next_keyword_end_index).trim_prefix("[").trim_suffix("]").split(", ")
			
			
			memory_type = MemoryData.MemoryType.get(memory_data[0].capitalize())
			
			display_name = memory_data[1] if memory_data.size() == 2 else memory_key
			
			MemoryDB._register(memory_key, memory_type, display_name)
			
			# Search for the next keyword
			search_index = memory_data_end_index + 1
			next_keyword_occurence_index = line.find("{", search_index)


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


func queue_visit(visit_name : String, delay : int, priority : int = 0):
	var next_visit = VisitorInstance.new()
	next_visit.person = self
	next_visit.visit_branch = visit_name
	next_visit.visit_time = VisitorManager.time + delay
	next_visit.visit_priority = priority
	
	VisitorManager.add_visitor_to_queue(next_visit)

func dialogue_concluded():
	if VisitorManager.current_visitor_name != visitor_name:
		return
	
	if !can_submit:
		return
	
	if not takes_inputs:
		return
	
	# If there is an ending, do nothing else
	if endingID != "":
		get_node("%BlackScreen").appear(endingID)
		return
	
	
	# Update any visitor states
	if (dialogues[current_visit_branch])[current_dialogue_branch].has("setState"):
		for state in dialogues[current_visit_branch][current_dialogue_branch]["setState"]:
			visitor_states[state] = str_to_var(dialogues[current_visit_branch][current_dialogue_branch]["setState"][state])
	
	
	if current_dialogue_takes_cards:
		check_submissions()
	elif dialogues[current_visit_branch][current_dialogue_branch].has("result"): 
		# The new dialogue links to some other dialogue without accepting cards
		set_dialogue_branch(dialogues[current_visit_branch][current_dialogue_branch]["result"])
	else:
		#character sprites change and animation
		if has_node("CharacterSprite"):
			can_submit = false
			var sprite = $CharacterSprite
			
			var tween = create_tween()
			tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
			tween.parallel().tween_property(dialogue_box, "modulate:a", 0.0, 0.5)
			
			await tween.finished
			
			sprite.visible = false
			can_submit = true
		VisitorManager.send_next_visitor()


func check_submissions():
	var submissions := []
	
	for i in range(instantiated_submission_box_count):
		submissions.append(null)
	
	# Get the card in each box
	for child in get_children():
		if child is SubmissionBox:
			var submission_data = child.get_card_data()
			if submission_data:
				submissions[child.get_box_index()] = submission_data["content"]
			else:
				submissions[child.get_box_index()] = null
				
	for case_name : String in dialogues[current_visit_branch][current_dialogue_branch]["cases"]:
		var case_data = dialogues[current_visit_branch][current_dialogue_branch]["cases"][case_name]
		var case_match := true
		
		# Check card submissions
		if case_data.has("submissions"):
			for requirement_index in case_data["submissions"].size():
				
				if case_data["submissions"][requirement_index] == "ANY":
					continue
				elif case_data["submissions"][requirement_index] == "EMPTY" and submissions[requirement_index] == null:
					continue
				elif case_data["submissions"][requirement_index] == submissions[requirement_index]:
					continue
					
				# If this code executes, there was a mismatched card
				case_match = false
		
		# Check states
		if case_data.has("stateChecks"):
			for check in case_data["stateChecks"]:
				if not visitor_states.has(check):
					push_error("This visitor: " + self.name + ", does not have the state: ", check)
					case_match = false
				elif str_to_var(case_data["stateChecks"][check]) != visitor_states[check]:
					case_match = false
		
		if case_match:
			# Show response dialogue
			set_dialogue_branch(case_data["result"])
			
			break

func create_submission_box(type : String):
	var box_instance = box_scene.instantiate()
	if box_instance:
		box_instance.z_index = 1
		
		# Set the accepted card type based on the parameter
		box_instance.initialize(type.capitalize(), instantiated_submission_box_count)
		
		
		box_instance.global_position = SUBMISSION_BOX_POSITIONS[instantiated_submission_box_count]
		instantiated_submission_box_count += 1
		add_child(box_instance)
	else:
		push_error("Failed to instantiate submission box")

func delete_submission_boxes():
	for child in get_children():
		if child is SubmissionBox:
			child.queue_free()

#preload of character arts
func load_character_sprite():
	var sprite_path = "res://Assets/" + visitor_name + ".png"
	
	if FileAccess.file_exists(sprite_path):
		var texture = load(sprite_path)
		$CharacterSprite.texture = texture
		
		var tex_h = texture.get_height()
		var target_h = SCREEN_HEIGHT * TARGET_SCREEN_HEIGHT_RATIO
		var scale_factor = target_h / tex_h
		$CharacterSprite.scale = Vector2(scale_factor, scale_factor)
		$CharacterSprite.position = Vector2(CHAR_POSITION_X, CHAR_POSITION_Y)
		
		$CharacterSprite.visible = false 
		
	else:
		push_warning("BaseVisitor: Can't find arts -> " + sprite_path)
