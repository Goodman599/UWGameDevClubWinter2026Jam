extends BaseVisitor

# The Demon.

func _init():	
	visitor_states = {
		
	}
	
	


func _ready(): 
	super()
	# add first visit to queue
	var next_visit = VisitorInstance.new()
	next_visit.person = self
	next_visit.visit_branch = "visit0"
	next_visit.visit_time = 0
	
	VisitorManager.add_visitor_to_queue(next_visit)
	VisitorManager.send_next_visitor()
