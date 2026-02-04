extends BaseVisitor

# The Cultist.

func _init():	
	visitor_states = {
		"Nurses_Writing_Submitted": false,
		"Strong_Sedatives_Submitted": false,
		"Anime_Poster_Submitted": false,
		"Blanket_Submitted": false,
		"Signed_Baseball_Submitted": false,
		"Friends_Card_Submitted": false,
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
	
	
