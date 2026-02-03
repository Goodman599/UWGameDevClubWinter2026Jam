extends Node
class_name VisitorInstance

var person : BaseVisitor
var visit_branch : String
var visit_priority : int
var visit_time : int = 0


func get_visit_time() -> int:
	return visit_time

func get_visit_priority() -> int:
	return visit_priority
