extends BaseVisitor

# Example visitor.


# Dialogue is stored as a dictionary (not memory efficient but who cares)
#	The keys are the "names of the branch" and the value is an array of dialogues.
func _init():	
	var data = load_json_as_dict("res://Dialogues/David_Doyle.json")
	push_error(data)
	
	dialogues = {"first" : ["Hello, you're finally awake.",
							"You got into a {car crash}.",
							"Thankfully, I, {Jimmy Jones}, was there to pull you out."],
				"second" : ["blah"],
				"third" : ["blah2"],}


func _ready(): 
	# Connect the 2 buttons. Please tell me there's a better way to do this...
	super()
	
	# Temporary code just to start a dialogue
	show_text(dialogues["first"][current_dialogue_index])
	current_dialogue_branch = "first"
	
func load_json_as_dict(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: " + path)
		return {}
	var json_text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_error("JSON parse error: %s at line %d" % [json.get_error_message(), json.get_error_line()])
		return {}
	return json.data
	
	#if DialogueManager.has_shown_first:
		#send_to_manager(new VisitorInstance(self, "second", current_day + 1))
	#elif DialogueManager.has_shown_second and DialogueManager.day % 7 == 5:
		#send_to_manager(new VisitorInstance(self, "third"))
