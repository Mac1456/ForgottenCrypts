extends CharacterBody2D
class_name Player

# Player state enums
enum PlayerState {
	IDLE,
	MOVING,
	ATTACKING,
	DASHING,
	DEAD,
	STUNNED
}

# Character type (set by derived classes)
var character_type: ProgressionManager.CharacterType = ProgressionManager.CharacterType.WIZARD

# Network identification
var player_id: int = 1
var player_name: String = "Player"
var is_local_player: bool = false

# Character stats (loaded from ProgressionManager)
var max_health: int = 100
var current_health: int = 100
var attack_power: int = 50
var move_speed: int = 100
var mana: int = 100
var current_mana: int = 100

# Movement and physics
var input_vector: Vector2 = Vector2.ZERO
var dash_velocity: Vector2 = Vector2.ZERO
var dash_speed: float = 300.0
var dash_duration: float = 0.2
var is_dashing: bool = false

# Combat state
var current_state: PlayerState = PlayerState.IDLE
var is_invincible: bool = false
var targets_in_range: Array = []

# Ability cooldowns
var ability1_ready: bool = true
var ability2_ready: bool = true
var ability3_ready: bool = true
var dash_ready: bool = true

# UI nodes (accessed via get_node when needed)
var sprite: Sprite2D
var health_bar: ProgressBar
var player_name_label: Label
var attack_range: Area2D
var hurt_box: Area2D

# Timer nodes (accessed via get_node when needed)
var ability1_timer: Timer
var ability2_timer: Timer
var ability3_timer: Timer
var dash_timer: Timer
var invincibility_timer: Timer

# Audio nodes (accessed via get_node when needed)
var movement_audio: AudioStreamPlayer2D
var attack_audio: AudioStreamPlayer2D
var hurt_audio: AudioStreamPlayer2D

# Signals
signal player_died(player_id: int)
signal player_took_damage(player_id: int, damage: int)
signal ability_used(player_id: int, ability_name: String)

func _ready():
	print("Player initialized: ", player_name)
	
	# Initialize node references
	_initialize_node_references()
	
	# Set up player name
	if player_name_label:
		player_name_label.text = player_name
	else:
		print("Warning: player_name_label UI node not found")
	
	# Load character stats
	load_character_stats()
	
	# Set up networking
	set_multiplayer_authority(player_id)
	
	# Connect to network signals
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	
	# Update UI
	update_health_bar()
	update_sprite()

func _initialize_node_references():
	# Get UI nodes
	sprite = get_node_or_null("Sprite2D")
	health_bar = get_node_or_null("HealthBar")
	player_name_label = get_node_or_null("PlayerName")
	attack_range = get_node_or_null("AttackRange")
	hurt_box = get_node_or_null("HurtBox")
	
	# Get timer nodes
	ability1_timer = get_node_or_null("AbilityCooldowns/Ability1Timer")
	ability2_timer = get_node_or_null("AbilityCooldowns/Ability2Timer")
	ability3_timer = get_node_or_null("AbilityCooldowns/Ability3Timer")
	dash_timer = get_node_or_null("AbilityCooldowns/DashTimer")
	invincibility_timer = get_node_or_null("StateManager/InvincibilityTimer")
	
	# Get audio nodes
	movement_audio = get_node_or_null("AudioManager/MovementAudio")
	attack_audio = get_node_or_null("AudioManager/AttackAudio")
	hurt_audio = get_node_or_null("AudioManager/HurtAudio")
	
	# Enable camera for local player
	var camera = get_node_or_null("Camera2D")
	if camera:
		camera.enabled = is_local_player
		print("Camera enabled for local player: ", is_local_player)
	
	print("Node references initialized")

func _physics_process(delta):
	if is_local_player:
		handle_input()
	
	handle_movement(delta)
	handle_state_updates()
	
	# Network sync
	if is_local_player:
		# Simple position sync without RPC for now
		pass

func handle_input():
	if current_state == PlayerState.DEAD:
		return
	
	# Movement input
	input_vector = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()
	
	# Ability inputs
	if Input.is_action_just_pressed("ability_1") and ability1_ready:
		use_ability_1()
	
	if Input.is_action_just_pressed("ability_2") and ability2_ready:
		use_ability_2()
	
	if Input.is_action_just_pressed("ability_3") and ability3_ready:
		use_ability_3()
	
	if Input.is_action_just_pressed("dash") and dash_ready:
		dash()

func handle_movement(delta):
	if current_state == PlayerState.DASHING:
		# Dash movement
		velocity = dash_velocity
		if is_dashing:
			await get_tree().create_timer(dash_duration).timeout
			is_dashing = false
			current_state = PlayerState.IDLE
	elif current_state != PlayerState.ATTACKING and current_state != PlayerState.STUNNED:
		# Normal movement
		velocity = input_vector * move_speed
	else:
		# Reduce velocity when attacking or stunned
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta * 2)
	
	move_and_slide()

func handle_state_updates():
	# Update animation based on state
	if current_state == PlayerState.MOVING and velocity.length() > 0:
		# Moving animation
		pass
	elif current_state == PlayerState.IDLE:
		# Idle animation
		pass
	elif current_state == PlayerState.ATTACKING:
		# Attack animation
		pass

func load_character_stats():
	var char_data = ProgressionManager.get_character_data(character_type)
	var stats = char_data.get("stats", {})
	
	max_health = stats.get("max_health", 100)
	current_health = max_health
	attack_power = stats.get("attack_power", 50)
	move_speed = stats.get("move_speed", 100)
	mana = stats.get("mana", 100)
	current_mana = mana
	
	print("Loaded stats for ", char_data.get("name", "Unknown"), ": HP=", max_health, " ATK=", attack_power, " SPD=", move_speed)

func update_sprite():
	# Set sprite frame based on character type
	if sprite:
		match character_type:
			ProgressionManager.CharacterType.WIZARD:
				sprite.frame = 40  # 5th row, 1st column (5*8 + 0)
			ProgressionManager.CharacterType.BARBARIAN:
				sprite.frame = 32  # 4th row, 1st column (4*8 + 0)
			ProgressionManager.CharacterType.ROGUE:
				sprite.frame = 3   # 1st row, 4th column (0*8 + 3)
			ProgressionManager.CharacterType.KNIGHT:
				sprite.frame = 8   # 2nd row, 1st column (1*8 + 0)
	else:
		print("Warning: sprite node not found for character type: ", character_type)

func update_health_bar():
	if health_bar:
		health_bar.value = (float(current_health) / float(max_health)) * 100.0
		
		# Change color based on health
		if current_health <= max_health * 0.25:
			health_bar.modulate = Color.RED
		elif current_health <= max_health * 0.5:
			health_bar.modulate = Color.YELLOW
		else:
			health_bar.modulate = Color.GREEN
	else:
		print("Warning: health_bar node not found")

# Combat functions
func take_damage(damage: int, attacker_id: int = -1):
	if is_invincible or current_state == PlayerState.DEAD:
		return
	
	current_health -= damage
	current_health = max(0, current_health)
	
	# Update UI
	update_health_bar()
	
	# Play hurt audio
	if hurt_audio:
		hurt_audio.play()
	
	# Become invincible briefly
	is_invincible = true
	invincibility_timer.start()
	
	# Flash sprite
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	# Emit signal
	player_took_damage.emit(player_id, damage)
	
	# Network sync
	if is_local_player:
		NetworkManager.sync_player_health(player_id, current_health, max_health)
	
	# Check for death
	if current_health <= 0:
		die()
	
	print("Player ", player_name, " took ", damage, " damage. Health: ", current_health, "/", max_health)

func heal(amount: int):
	current_health = min(max_health, current_health + amount)
	update_health_bar()
	
	# Network sync
	if is_local_player:
		NetworkManager.sync_player_health(player_id, current_health, max_health)
	
	print("Player ", player_name, " healed for ", amount, ". Health: ", current_health, "/", max_health)

func die():
	current_state = PlayerState.DEAD
	
	# Play death animation
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.TRANSPARENT, 1.0)
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 1.0)
	
	# Emit signal
	player_died.emit(player_id)
	
	# Network sync
	if is_local_player:
		NetworkManager.player_died(player_id)
		GameManager.handle_player_death(player_id)
	
	print("Player ", player_name, " has died!")

func revive(health: int = 50):
	current_health = min(max_health, health)
	current_state = PlayerState.IDLE
	
	# Reset sprite
	sprite.modulate = Color.WHITE
	sprite.scale = Vector2.ONE
	
	# Update UI
	update_health_bar()
	
	print("Player ", player_name, " has been revived with ", current_health, " health!")

# Ability functions (to be overridden by character-specific classes)
func use_ability_1():
	if current_state == PlayerState.DEAD or not ability1_ready:
		return
	
	print("Using ability 1 (base implementation)")
	ability1_ready = false
	ability1_timer.start()
	
	# Network sync
	if is_local_player:
		ability_used.emit(player_id, "ability_1")

func use_ability_2():
	if current_state == PlayerState.DEAD or not ability2_ready:
		return
	
	print("Using ability 2 (base implementation)")
	ability2_ready = false
	ability2_timer.start()
	
	# Network sync
	if is_local_player:
		ability_used.emit(player_id, "ability_2")

func use_ability_3():
	if current_state == PlayerState.DEAD or not ability3_ready:
		return
	
	# Check if third ability is unlocked
	var char_data = ProgressionManager.get_character_data(character_type)
	if not char_data.get("third_ability_unlocked", false):
		print("Third ability not unlocked yet!")
		return
	
	print("Using ability 3 (base implementation)")
	ability3_ready = false
	ability3_timer.start()
	
	# Network sync
	if is_local_player:
		ability_used.emit(player_id, "ability_3")

func dash():
	if current_state == PlayerState.DEAD or not dash_ready:
		return
	
	# Calculate dash direction
	var dash_direction = input_vector
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2(0, -1)  # Default dash up
	
	# Start dash
	current_state = PlayerState.DASHING
	is_dashing = true
	dash_velocity = dash_direction * dash_speed
	dash_ready = false
	dash_timer.start()
	
	# Become invincible during dash
	is_invincible = true
	
	print("Player ", player_name, " dashed!")

# Signal handlers
func _on_attack_range_area_entered(area):
	if area.get_parent() != self:
		targets_in_range.append(area.get_parent())

func _on_attack_range_area_exited(area):
	if area.get_parent() in targets_in_range:
		targets_in_range.erase(area.get_parent())

func _on_hurt_box_area_entered(area):
	# Handle incoming damage from projectiles/enemies
	if area.has_method("get_damage"):
		var damage = area.get_damage()
		take_damage(damage)

func _on_ability_1_timer_timeout():
	ability1_ready = true
	print("Ability 1 ready")

func _on_ability_2_timer_timeout():
	ability2_ready = true
	print("Ability 2 ready")

func _on_ability_3_timer_timeout():
	ability3_ready = true
	print("Ability 3 ready")

func _on_dash_timer_timeout():
	dash_ready = true
	print("Dash ready")

func _on_invincibility_timer_timeout():
	is_invincible = false

func _on_player_disconnected(id: int):
	if id == player_id:
		queue_free()

# Network synchronization (temporarily disabled)
# func sync_player_position():
#	if is_local_player:
#		rpc("update_player_position", global_position, velocity)

# @rpc("any_peer", "call_local", "unreliable")
# func update_player_position(pos: Vector2, vel: Vector2):
#	if not is_local_player:
#		global_position = pos
#		velocity = vel

# Ability system
func is_ability_ready(ability_num: int) -> bool:
	match ability_num:
		1:
			return ability1_ready
		2:
			return ability2_ready
		3:
			return ability3_ready
		_:
			return false

# Setup functions
func initialize_player(id: int, name: String, char_type: ProgressionManager.CharacterType, is_local: bool = false):
	print("Initializing player - ID: ", id, ", Name: ", name, ", Type: ", char_type)
	
	# Validate parameters
	if id <= 0:
		push_error("Invalid player ID: ", id)
		return
	
	if name.is_empty():
		push_error("Player name cannot be empty")
		return
	
	player_id = id
	player_name = name
	character_type = char_type
	is_local_player = is_local
	
	print("Initializing node references...")
	# Initialize node references (important when script is set after instantiation)
	_initialize_node_references()
	
	print("Setting up networking...")
	# Set up networking
	set_multiplayer_authority(player_id)
	
	print("Updating display...")
	# Update display
	if player_name_label:
		player_name_label.text = player_name
	else:
		print("Warning: player_name_label UI node not found")
	
	print("Loading character stats...")
	load_character_stats()
	
	print("Updating sprite...")
	update_sprite()
	
	print("Updating health bar...")
	update_health_bar()
	
	print("Player initialization complete for: ", player_name, " (", ProgressionManager.CharacterType.keys()[character_type], ")")
