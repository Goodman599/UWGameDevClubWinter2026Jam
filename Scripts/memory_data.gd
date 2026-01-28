extends Node
class_name MemoryData

enum MemoryType{Person, Event, Feeling}

@export var id: String
@export var type: MemoryType = MemoryType.Person
@export var display_text: String =""
