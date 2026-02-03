extends Node
class_name VisitorManager

var time = 0 # 0 - 41, one for each day and night

var visitor_queue : Array[VisitorInstance]

# Takes and adds a VisitorInstance to the queue, and sorts the queue chronologically
func add_visitor_to_queue(visitor : VisitorInstance):
	visitor_queue.append(visitor)
	visitor_queue.sort_custom(func(a, b): return a.get_visit_time < b.get_visit_time)



func on_day_change():
	temp() # I Can't think of a good method name


# Requires visitor_queue to be sorted chronologically
# Summons visitors scheduled for the current time
func temp():
	for visitor in visitor_queue:
		if visitor.get_visit_time() > time:
			break
		if visitor.get_visit_time() == time:
			"Summon them"


#func flag_changer(visitor_name : String, flag : String, state):
	#visitor.info[flag] = state
