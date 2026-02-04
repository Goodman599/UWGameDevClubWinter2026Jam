extends BaseVisitor

# The Cultist.

var good_submissions := 0
var total_submissions := 0
var success := false 

func _init():	
	visitor_states = {
		"Nurse's_Writing_Submitted": false,
		"Strong_Sedatives_Submitted": false,
		"Anime_Poster_Submitted": false,
		"Blanket_Submitted": false,
		"Signed_Baseball_Submitted": false,
		"Friend's_Card_Submitted": false,
		"Souvenir_Submitted": false,
		"Flowers_Submitted": false,
		
		"Last_Submission": false
	}

func _ready(): 
	super()
	# add first visit to queue
	var next_visit = VisitorInstance.new()
	next_visit.person = self
	next_visit.visit_branch = "visit0"
	next_visit.visit_time = 5
	VisitorManager.add_visitor_to_queue(next_visit)
	
func add_final_visit(ending: String):
	var next_visit = VisitorInstance.new()
	next_visit.person = self
	next_visit.visit_branch = ending
	next_visit.visit_time = 33 # night 17
	print("adding ending " , ending)
	VisitorManager.add_visitor_to_queue(next_visit)
	
func check_condition(flag: int):
	print("checking cultist condition")
	total_submissions += 1
	if total_submissions >= 3:		
	
		var detective_node := get_parent().get_node("Detective")
		var detective_succeeded : bool = detective_node.success
		
		good_submissions = 0
		for item in visitor_states.keys():
			print("item: ", item)
			if item ==  "Anime_Poster_Submitted" or item == "Blanket_Submitted" or item == "Signed_Baseball_Submitted" or item == "Friend's_Card_Submitted":
				
				if visitor_states[item] == true:
					print(visitor_states[item])
					good_submissions += 1
					
		if good_submissions < 2:
			success = false
		else:
			success = true
			
		if success == false:
			if detective_succeeded:
				add_final_visit("failure")
			else:
				add_final_visit("neutral")
		else:
			if detective_succeeded:
				add_final_visit("tie")
			else:
				add_final_visit("success")
				
	
	print(flag)
	print(good_submissions)
	print(total_submissions)
	print(success)
