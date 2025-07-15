extends Node

# Simplified AudioManager - backup version without complex audio loading
# Use this if the main AudioManager is causing startup crashes

# Audio players
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer

# Volume settings
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var ambient_volume: float = 0.5

# Current playing music
var current_music: String = ""

# Signals
signal music_changed(track_name: String)
signal volume_changed(volume_type: String, new_volume: float)

func _ready():
	print("AudioManager (backup) initialized")
	
	# Create audio players
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.volume_db = _linear_to_db(master_volume * music_volume)
	add_child(music_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.volume_db = _linear_to_db(master_volume * sfx_volume)
	add_child(sfx_player)
	
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.volume_db = _linear_to_db(master_volume * ambient_volume)
	add_child(ambient_player)
	
	# Connect to game events
	_connect_to_game_events()
	
	print("AudioManager (backup) ready - audio disabled to prevent crashes")

# Simplified play functions that don't try to load files
func play_music(track_name: String, fade_in: bool = true):
	print("AudioManager (backup): Would play music: ", track_name)
	current_music = track_name
	music_changed.emit(track_name)

func play_sfx(effect_name: String, volume_modifier: float = 1.0):
	print("AudioManager (backup): Would play SFX: ", effect_name)

func play_ambient(sound_name: String, loop: bool = true):
	print("AudioManager (backup): Would play ambient: ", sound_name)

func stop_music(fade_out: bool = true):
	music_player.stop()
	current_music = ""

func stop_ambient():
	ambient_player.stop()

# Volume functions
func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	_update_all_volumes()
	volume_changed.emit("master", master_volume)

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	music_player.volume_db = _linear_to_db(master_volume * music_volume)
	volume_changed.emit("music", music_volume)

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	sfx_player.volume_db = _linear_to_db(master_volume * sfx_volume)
	volume_changed.emit("sfx", sfx_volume)

func set_ambient_volume(volume: float):
	ambient_volume = clamp(volume, 0.0, 1.0)
	ambient_player.volume_db = _linear_to_db(master_volume * ambient_volume)
	volume_changed.emit("ambient", ambient_volume)

# Get volume functions
func get_master_volume() -> float:
	return master_volume

func get_music_volume() -> float:
	return music_volume

func get_sfx_volume() -> float:
	return sfx_volume

func get_ambient_volume() -> float:
	return ambient_volume

# Utility functions
func _update_all_volumes():
	music_player.volume_db = _linear_to_db(master_volume * music_volume)
	sfx_player.volume_db = _linear_to_db(master_volume * sfx_volume)
	ambient_player.volume_db = _linear_to_db(master_volume * ambient_volume)

func _linear_to_db(linear_volume: float) -> float:
	if linear_volume <= 0.0:
		return -80.0
	return 20.0 * log(linear_volume) / log(10.0)

# Connect to game events
func _connect_to_game_events():
	# Safely connect to game events
	if get_node_or_null("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.has_signal("game_state_changed"):
			gm.game_state_changed.connect(_on_game_state_changed)
		if gm.has_signal("level_changed"):
			gm.level_changed.connect(_on_level_changed)

# Event handlers (simplified)
func _on_game_state_changed(new_state):
	print("AudioManager (backup): Game state changed to: ", new_state)

func _on_level_changed(new_level: int, level_info: Dictionary):
	print("AudioManager (backup): Level changed to: ", new_level)

# Utility functions for game events (all simplified)
func play_combat_sound(sound_type: String, source_position: Vector2 = Vector2.ZERO):
	print("AudioManager (backup): Would play combat sound: ", sound_type)

func play_ability_sound(ability_name: String):
	print("AudioManager (backup): Would play ability sound: ", ability_name)

func play_ui_sound(ui_action: String):
	print("AudioManager (backup): Would play UI sound: ", ui_action)

func play_environment_sound(environment_action: String):
	print("AudioManager (backup): Would play environment sound: ", environment_action)

# Status functions
func is_music_playing() -> bool:
	return music_player.playing

func is_sfx_playing() -> bool:
	return sfx_player.playing

func is_ambient_playing() -> bool:
	return ambient_player.playing

func get_current_music() -> String:
	return current_music 