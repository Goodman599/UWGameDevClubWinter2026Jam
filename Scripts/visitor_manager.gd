extends Node
class_name VisitorManager

var day = 1 # 1 - 28

visitor_queue = [VisitorInstance1, VisitorInstance2, VisitorInstance3 ]


func on_day_change():
	for visitor in visitor_queue:
		if day is correct:
			send them in

func populate_queue():
	add daily visitors to queue

func flag_changer(visitor_name : String, flag : String, state):
	visitor.info[flag] = state
	
	
###
#detective: 
	#info = {
		#"cultists arrested" : false
	#}
#
#cultist:
	#on_being_tricked:
		#VisitorManager.flag_changer("detective", "cultists arrested", true)
###
