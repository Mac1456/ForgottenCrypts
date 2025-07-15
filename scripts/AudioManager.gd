extends Node

# Audio players
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer

# Volume settings
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var ambient_volume: float = 0.5

# Music tracks
var music_tracks: Dictionary = {
	"menu": "res://assets/audio/music/menu_theme.ogg",
	"cave": "res://assets/audio/music/cave_ambient.ogg",
	"catacomb": "res://assets/audio/music/catacomb_ambient.ogg",
	"crypt": "res://assets/audio/music/crypt_ambient.ogg",
	"castle": "res://assets/audio/music/castle_ambient.ogg",
	"boss": "res://assets/audio/music/boss_theme.ogg",
	"victory": "res://assets/audio/music/victory_theme.ogg"
}

# Sound effects
var sound_effects: Dictionary = {
	# Combat sounds
	"player_attack": "res://assets/audio/sfx/player_attack.ogg",
	"player_hit": "res://assets/audio/sfx/player_hit.ogg",
	"player_death": "res://assets/audio/sfx/player_death.ogg",
	"enemy_hit": "res://assets/audio/sfx/enemy_hit.ogg",
	"enemy_death": "res://assets/audio/sfx/enemy_death.ogg",
	
	# Abilities
	"fireball": "res://assets/audio/sfx/fireball.ogg",
	"magic_missile": "res://assets/audio/sfx/magic_missile.ogg",
	"heavy_strike": "res://assets/audio/sfx/heavy_strike.ogg",
	"berserker_rage": "res://assets/audio/sfx/berserker_rage.ogg",
	"stealth": "res://assets/audio/sfx/stealth.ogg",
	"poison_strike": "res://assets/audio/sfx/poison_strike.ogg",
	"shield_bash": "res://assets/audio/sfx/shield_bash.ogg",
	"protective_aura": "res://assets/audio/sfx/protective_aura.ogg",
	
	# UI sounds
	"button_click": "res://assets/audio/sfx/button_click.ogg",
	"button_hover": "res://assets/audio/sfx/button_hover.ogg",
	"level_up": "res://assets/audio/sfx/level_up.ogg",
	"upgrade_purchase": "res://assets/audio/sfx/upgrade_purchase.ogg",
	"item_pickup": "res://assets/audio/sfx/item_pickup.ogg",
	
	# Environment
	"door_open": "res://assets/audio/sfx/door_open.ogg",
	"chest_open": "res://assets/audio/sfx/chest_open.ogg",
	"boss_spawn": "res://assets/audio/sfx/boss_spawn.ogg",
	"boss_phase": "res://assets/audio/sfx/boss_phase.ogg",
	"teleport": "res://assets/audio/sfx/teleport.ogg",
	"heal": "res://assets/audio/sfx/heal.ogg"
}

# Current playing music
var current_music: String = ""

# Signals
signal music_changed(track_name: String)
signal volume_changed(volume_type: String, new_volume: float)

func _ready():
	print("AudioManager initialized")
	
	# Create audio players
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.volume_db = _linear_to_db(master_volume * music_volume)
	music_player.bus = "Music"
	add_child(music_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.volume_db = _linear_to_db(master_volume * sfx_volume)
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.volume_db = _linear_to_db(master_volume * ambient_volume)
	ambient_player.bus = "Ambient"
	add_child(ambient_player)
	
	# Load volume settings
	_load_audio_settings()
	
	# Connect to game events
	_connect_to_game_events()

# Play music track
func play_music(track_name: String, fade_in: bool = true):
	if current_music == track_name and music_player.playing:
		return
	
	print("Playing music: ", track_name)
	
	# Stop current music if playing
	if music_player.playing:
		if fade_in:
			_fade_out_music()
		else:
			music_player.stop()
	
	# Instead of loading, use silent placeholder
	var audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = 22050
	audio_stream.buffer_length = 0.1
	music_player.stream = audio_stream
	music_player.play()
	current_music = track_name
	
	if fade_in:
		_fade_in_music()
		music_changed.emit(track_name)

# Play sound effect
func play_sfx(effect_name: String, volume_modifier: float = 1.0):
	if effect_name in sound_effects:
		var effect_path = sound_effects[effect_name]
		
		# Try to load the audio file
		var audio_stream = _load_audio_file(effect_path)
		if audio_stream:
			sfx_player.stream = audio_stream
			sfx_player.volume_db = _linear_to_db(master_volume * sfx_volume * volume_modifier)
			sfx_player.play()
		else:
			print("Failed to load sound effect: ", effect_path, " - continuing without sound")
			# Don't play placeholder - just continue silently
	else:
		print("Sound effect not found: ", effect_name, " - continuing without sound")

# Play ambient sound
func play_ambient(sound_name: String, loop: bool = true):
	print("Playing ambient: ", sound_name)
	
	if sound_name in sound_effects:
		var sound_path = sound_effects[sound_name]
		
		# Try to load the audio file
		var audio_stream = _load_audio_file(sound_path)
		if audio_stream:
			ambient_player.stream = audio_stream
			ambient_player.play()
			
			if loop and audio_stream is AudioStreamOggVorbis:
				audio_stream.loop = true
		else:
			print("Failed to load ambient sound: ", sound_path, " - continuing without ambient sound")

# Stop music
func stop_music(fade_out: bool = true):
	if fade_out:
		_fade_out_music()
	else:
		music_player.stop()
	current_music = ""

# Stop ambient sound
func stop_ambient():
	ambient_player.stop()

# Set volume levels
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

# Get volume levels
func get_master_volume() -> float:
	return master_volume

func get_music_volume() -> float:
	return music_volume

func get_sfx_volume() -> float:
	return sfx_volume

func get_ambient_volume() -> float:
	return ambient_volume

# Load audio file with fallback (non-blocking)
func _load_audio_file(path: String) -> AudioStream:
	print("Attempting to load audio file: ", path)
	
	if not ResourceLoader.exists(path):
		print("Audio file not found: ", path)
		return null
	
	# Use ResourceLoader.load instead of load() for better error handling
	var audio_stream = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
	if audio_stream:
		print("Successfully loaded audio file: ", path)
		return audio_stream
	else:
		print("Failed to load audio file: ", path)
		var placeholder = AudioStreamGenerator.new()
		placeholder.mix_rate = 22050
		placeholder.buffer_length = 0.1
		return placeholder

# Play placeholder music when real music is missing
func _play_placeholder_music():
	print("Playing placeholder music")
	# Create a simple tone generator for placeholder music
	var placeholder_stream = AudioStreamGenerator.new()
	placeholder_stream.mix_rate = 22050
	placeholder_stream.buffer_length = 0.1
	music_player.stream = placeholder_stream
	music_player.play()

# Play placeholder sound effect
func _play_placeholder_sfx():
	print("Playing placeholder SFX")
	# Create a simple tone generator for placeholder sounds
	var placeholder_stream = AudioStreamGenerator.new()
	placeholder_stream.mix_rate = 22050
	placeholder_stream.buffer_length = 0.1
	sfx_player.stream = placeholder_stream
	sfx_player.play()

# Fade in music
func _fade_in_music():
	var tween = create_tween()
	music_player.volume_db = -80.0
	tween.tween_property(music_player, "volume_db", _linear_to_db(master_volume * music_volume), 1.0)

# Fade out music
func _fade_out_music():
	var tween = create_tween()
	var target_volume = -80.0
	tween.tween_property(music_player, "volume_db", target_volume, 1.0)
	tween.tween_callback(music_player.stop)

# Update all volume levels
func _update_all_volumes():
	music_player.volume_db = _linear_to_db(master_volume * music_volume)
	sfx_player.volume_db = _linear_to_db(master_volume * sfx_volume)
	ambient_player.volume_db = _linear_to_db(master_volume * ambient_volume)

# Convert linear volume to decibels
func _linear_to_db(linear_volume: float) -> float:
	if linear_volume <= 0.0:
		return -80.0
	return 20.0 * log(linear_volume) / log(10.0)

# Load audio settings from file
func _load_audio_settings():
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")
	
	if err == OK:
		master_volume = config.get_value("audio", "master_volume", 1.0)
		music_volume = config.get_value("audio", "music_volume", 0.7)
		sfx_volume = config.get_value("audio", "sfx_volume", 0.8)
		ambient_volume = config.get_value("audio", "ambient_volume", 0.5)
		
		_update_all_volumes()
		print("Audio settings loaded")
	else:
		print("No audio settings file found, using defaults")

# Save audio settings to file
func save_audio_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "ambient_volume", ambient_volume)
	
	config.save("user://audio_settings.cfg")
	print("Audio settings saved")

# Connect to game events
func _connect_to_game_events():
	# Connect to GameManager signals
	if GameManager:
		GameManager.game_state_changed.connect(_on_game_state_changed)
		GameManager.level_changed.connect(_on_level_changed)
		GameManager.boss_defeated.connect(_on_boss_defeated)
		GameManager.run_completed.connect(_on_run_completed)
		GameManager.run_failed.connect(_on_run_failed)
	
	# Connect to ProgressionManager signals
	if ProgressionManager:
		ProgressionManager.level_up.connect(_on_level_up)
		ProgressionManager.upgrade_purchased.connect(_on_upgrade_purchased)

# Game event handlers
func _on_game_state_changed(new_state):
	match new_state:
		GameManager.GameState.MENU:
			play_music("menu")
		GameManager.GameState.PLAYING:
			# Music will be set by level change
			pass
		GameManager.GameState.PAUSED:
			# Keep current music but lower volume
			set_music_volume(music_volume * 0.5)
		GameManager.GameState.GAME_OVER:
			stop_music()
		GameManager.GameState.VICTORY:
			play_music("victory")

func _on_level_changed(new_level: int, level_info: Dictionary):
	var level_type = level_info.get("type", GameManager.LevelType.CAVE)
	
	match level_type:
		GameManager.LevelType.CAVE:
			play_music("cave")
		GameManager.LevelType.CATACOMB:
			play_music("catacomb")
		GameManager.LevelType.CRYPT:
			play_music("crypt")
		GameManager.LevelType.CASTLE:
			play_music("castle")

func _on_boss_defeated(boss_type: String):
	play_sfx("boss_phase", 1.2)

func _on_run_completed(stats: Dictionary):
	play_music("victory")
	play_sfx("level_up", 1.5)

func _on_run_failed(reason: String):
	stop_music()
	play_sfx("player_death", 1.2)

func _on_level_up(character_type, new_level: int):
	play_sfx("level_up")

func _on_upgrade_purchased(character_type, upgrade_type: String):
	play_sfx("upgrade_purchase")

# Utility functions for specific game events
func play_combat_sound(sound_type: String, source_position: Vector2 = Vector2.ZERO):
	match sound_type:
		"player_attack":
			play_sfx("player_attack")
		"player_hit":
			play_sfx("player_hit")
		"player_death":
			play_sfx("player_death")
		"enemy_hit":
			play_sfx("enemy_hit")
		"enemy_death":
			play_sfx("enemy_death")

func play_ability_sound(ability_name: String):
	match ability_name:
		"fireball":
			play_sfx("fireball")
		"magic_missile":
			play_sfx("magic_missile")
		"heavy_strike":
			play_sfx("heavy_strike")
		"berserker_rage":
			play_sfx("berserker_rage")
		"stealth":
			play_sfx("stealth")
		"poison_strike":
			play_sfx("poison_strike")
		"shield_bash":
			play_sfx("shield_bash")
		"protective_aura":
			play_sfx("protective_aura")

func play_ui_sound(ui_action: String):
	match ui_action:
		"button_click":
			play_sfx("button_click")
		"button_hover":
			play_sfx("button_hover")
		"item_pickup":
			play_sfx("item_pickup")

func play_environment_sound(environment_action: String):
	match environment_action:
		"door_open":
			play_sfx("door_open")
		"chest_open":
			play_sfx("chest_open")
		"boss_spawn":
			play_sfx("boss_spawn", 1.5)
		"boss_phase":
			play_sfx("boss_phase", 1.3)
		"teleport":
			play_sfx("teleport")
		"heal":
			play_sfx("heal")

# Check if audio is currently playing
func is_music_playing() -> bool:
	return music_player.playing

func is_sfx_playing() -> bool:
	return sfx_player.playing

func is_ambient_playing() -> bool:
	return ambient_player.playing

# Get current music track
func get_current_music() -> String:
	return current_music 
