extends Node

var time = 0 # 0 - 41, one for each day and night

var visitor_queue : Array[VisitorInstance]
var current_visitor_name : String

#func _ready() -> void:
	#send_next_visitor();

# Takes and adds a VisitorInstance to the queue, and sorts the queue chronologically
func add_visitor_to_queue(visitor : VisitorInstance):
	visitor_queue.append(visitor)
	visitor_queue.sort_custom(func(a, b): return a.get_visit_time() < b.get_visit_time())

func send_next_visitor():
	print("time: ", time)
	print("queue: ", visitor_queue)
	var next_visit_instance : VisitorInstance = visitor_queue[0]
	if next_visit_instance.visit_time == time:
		next_visit_instance.person.set_visit_branch(next_visit_instance.visit_branch)
		visitor_queue.pop_front()
		current_visitor_name = next_visit_instance.person.visitor_name
	else:
		current_visitor_name = ""
		step_time()

func step_time():
	time += 1
	print("The time is: ", time)
	if time % 2 == 0:
		print("It's day now!")
	else:
		print("It's night now!")
	send_next_visitor()


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
