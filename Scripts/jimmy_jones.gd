extends BaseVisitor

# Example visitor.


# Dialogue is stored as a dictionary (not memory efficient but who cares)
#	The keys are the "names of the branch" and the value is an array of dialogues.
func _init():
	dialogues = {"first" : ["Hey you, you're finally awake.",
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
	
	
	
	#if DialogueManager.has_shown_first:
		#send_to_manager(new VisitorInstance(self, "second", current_day + 1))
	#elif DialogueManager.has_shown_second and DialogueManager.day % 7 == 5:
		#send_to_manager(new VisitorInstance(self, "third"))
