extends BaseVisitor

# The Detective.

var good_submissions := 0
var total_submissions := 0
var success := false

func _init():	
	visitor_states = {
		"Investigated_Cultist" = false,
		"Investigated_Demon" = false
	}
	
func _ready(): 
	super()
	# add first visit to queue
	var next_visit = VisitorInstance.new()
	next_visit.person = self
	next_visit.visit_branch = "visit0"
	next_visit.visit_time = 3
	
	VisitorManager.add_visitor_to_queue(next_visit)
	
func add_final_visit(ending: String):
	var next_visit = VisitorInstance.new()
	next_visit.person = self
	next_visit.visit_branch = ending
	next_visit.visit_time = 31 # day 16
	print("adding ending " , ending)
	VisitorManager.add_visitor_to_queue(next_visit)

func check_condition(flag: int):
	print("checking detective condition")
	total_submissions += 1
	print("new total: ", total_submissions)
	print(visitor_states["Investigated_Cultist"])
	print(visitor_states["Investigated_Demon"])
	if total_submissions >= 3:
		success = false
		if visitor_states["Investigated_Cultist"] == true && visitor_states["Investigated_Demon"] == true :
			success = true
		if success == true:
			add_final_visit("Day16Success")
		else:
			add_final_visit("Day16Failure")
