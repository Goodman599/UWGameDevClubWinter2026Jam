extends Node

var time = 0 # 0 - 41, one for each day and night
signal time_changed(is_day : bool)

var visitor_queue : Array[VisitorInstance]
var current_visitor_name : String


# Takes and adds a VisitorInstance to the queue, and sorts the queue chronologically
func add_visitor_to_queue(visitor : VisitorInstance):
	visitor_queue.append(visitor)
	visitor_queue.sort_custom(compare)

func compare(a, b):
	if a.get_visit_time() != b.get_visit_time():
		return a.get_visit_time() < b.get_visit_time()
	else:
		return a.get_visit_priority() > b.get_visit_priority()

func send_next_visitor():
	await get_tree().process_frame
	#print("time: ", time)
	#print("queue: ")
	#for visitor in visitor_queue:
		#print(visitor.person, " is visiting at ", visitor.get_visit_time(), " with priority ", visitor.get_visit_priority())
	if visitor_queue.size() == 0:
		print("You somehow ran out of visitors")
		return
	
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
	var is_day = (time % 2 == 1)
	if is_day:
		print("It's day now!")
	else:
		print("It's night now!")
	time_changed.emit(is_day)
	send_next_visitor()
