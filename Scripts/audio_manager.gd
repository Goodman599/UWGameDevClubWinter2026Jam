extends Node2D
class_name AudioManager

@onready var music_player: AudioStreamPlayer = $MainPlayer
@onready var ambience_player: AudioStreamPlayer = $AmbiencePlayer
@onready var dialogue_player: AudioStreamPlayer = $DialoguePlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

var current_music_track: String = ""

func _ready():
	# Start main theme and hospital ambience
	if get_parent().name == "StartMenu":
		play_start_music("Eerie")
	#play_music("Sigillum (Demon Version)")
	#play_ambience("Heartbeat - Looping")

	# Connect to visitor changes
	connect_to_visitor_manager()

func _process(delta):
	self.global_position = get_global_mouse_position()
	
	if $MainPlayer.playing == false:
		$MainPlayer.play()
		
	if $AmbiencePlayer.playing == false:
		$AmbiencePlayer.play()
	
	pass
	
func connect_to_visitor_manager():
	# Try different ways to find VisitorManager
	var visitor_manager
	
	# Check if it's an autoload
	if has_node("/root/VisitorManager"):
		visitor_manager = get_node("/root/VisitorManager")
	# Check if it's a child of Main
	elif has_node("/root/Main/VisitorManager"):
		visitor_manager = get_node("/root/Main/VisitorManager")
	# Check if it's a sibling
	elif get_parent() and get_parent().has_node("VisitorManager"):
		visitor_manager = get_parent().get_node("VisitorManager")
	
	if visitor_manager and visitor_manager.has_signal("time_changed"):
		visitor_manager.time_changed.connect(_on_time_changed)

func play_music(track_name: String):
	if current_music_track == track_name:
		return  # Already playing this track
	
	var path = "res://Musics/" + track_name + ".mp3"
	var stream = load(path)
	
	if stream:
		current_music_track = track_name
		music_player.stream = stream
		music_player.play()

func play_ambience(ambience_name: String):
	var path = "res://Musics/Looping Ambiences/" + ambience_name + ".wav"
	var stream = load(path)
	if stream:
		ambience_player.stream = stream
		ambience_player.play()

func play_dialogue_sound(visitor_name: String):
	var path = ""
	if visitor_name == "Demon":
		path = "res://Musics/Demon speaks (Play oneshot on start of line_)/Demon 1.wav"
	else:
		path = "res://Musics/Character Speaking Blips/" + visitor_name + ".wav"
	
	var stream = load(path)
	if stream:
		dialogue_player.stream = stream
		dialogue_player.play()

func play_ui_sound(sound_name: String):
	var path = "res://Musics/UI-Card Sounds/" + sound_name + ".wav"
	var stream = load(path)
	if stream:
		sfx_player.stream = stream
		sfx_player.play()

func play_start_music(track_name: String):
	if current_music_track == track_name:
		return
	
	var path = "res://Musics/Eerie.mp3"
	var stream = load(path)
	
	if stream:
		current_music_track = track_name
		music_player.stream = stream
		music_player.play()

func stop_start_music():
	if music_player.playing:
		music_player.stop()
	
	current_music_track = ""

func play_click():
	play_ui_sound("Click")
	
func play_hover():
	play_ui_sound("Hover")
	
func play_choice_confirm():
	play_ui_sound("Lock in choice_Confirm")
	
func play_pick_up_card():
	play_ui_sound("Pick up card")
	
func play_put_down_card():
	play_ui_sound("Put down card")

func _on_time_changed(is_day: bool):
	if is_day:
		# Switch to day theme
		play_music("Sigillum (Main Theme)")
		play_ambience("Heart Monitor Ambience - Looping")
	else:
		# Switch to demon/night theme
		play_music("Sigillum (Demon Version)")
		play_ambience("Heartbeat - Looping")
