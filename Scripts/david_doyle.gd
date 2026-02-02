extends BaseVisitor

# Example visitor.

func _init():	
	visitor_states = {
		"mentioned_JJ" = false
	}


func _ready(): 
	# Connect the 2 buttons. Please tell me there's a better way to do this...
	super()
	# Temporary code just to start a dialogue
	set_visit_branch("visit0")
