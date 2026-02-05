extends CanvasLayer

var current_dialogue_index = 0
var endings := {}
var endingID := ""
var in_text_transition := true

func _ready():
	$Background.modulate = Color(1, 1, 1, 0)
	$Text.self_modulate = Color(1, 1, 1, 0) 
	endings = load_json_as_dict("res://Dialogues/Endings.json")

func load_ending(newEndingID : String):
	endingID = newEndingID
	$Text.text = endings[endingID][0]

func appear(newEndingID : String):
	show()
	var tween = get_tree().create_tween()
	tween.tween_property($Background, "modulate", Color(1, 1, 1, 1), 2)
	await tween.finished
	
	load_ending(newEndingID)
	
	tween = get_tree().create_tween()
	tween.tween_property($Text, "self_modulate", Color(1, 1, 1, 1), 1)
	in_text_transition = false
	


func show_next():
	if in_text_transition:
		return
	
	if current_dialogue_index < endings[endingID].size() - 1:
		in_text_transition = true
		var tween = get_tree().create_tween()
		tween.tween_property($Text, "self_modulate", Color(1, 1, 1, 0), 1)
		await tween.finished
		current_dialogue_index += 1
		$Text.text = endings[endingID][current_dialogue_index]
		tween = get_tree().create_tween()
		tween.tween_property($Text, "self_modulate", Color(1, 1, 1, 1), 1)
		in_text_transition = false
	elif current_dialogue_index == endings[endingID].size() - 1:
		get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			show_next()



# Takes a file path and returns a json as a dictionary
func load_json_as_dict(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: " + path + ". Make sure the name of the visitor is set correctly")
		return {}
	var json_text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_error("JSON parse error: %s at line %d" % [json.get_error_message(), json.get_error_line()])
		return {}
	return json.data
