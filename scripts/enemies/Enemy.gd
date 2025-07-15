extends CharacterBody2D
class_name Enemy

# Enemy state enums
enum EnemyState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	STUNNED,
	DEAD
}

# Enemy type
enum EnemyType {
	SKELETON_GRUNT,
	SKELETON_ARCHER,
	SKELETON_GUARD,
	SKELETON_BOMBER,
	ELITE_SKELETON,
	WITCH_MINI,
	WITCH_FINAL
}

# Core enemy properties
var enemy_type: EnemyType = EnemyType.SKELETON_GRUNT
var enemy_name: String = "Enemy"
var max_health: int = 50
var current_health: int = 50
var attack_power: int = 20
var move_speed: int = 80
var detection_radius: float = 120.0
var attack_range: float = 40.0
var patrol_radius: float = 80.0

# AI state
var current_state: EnemyState = EnemyState.IDLE
var target_player: Node = null
var spawn_position: Vector2
var patrol_target: Vector2
var last_known_player_position: Vector2
var state_timer: float = 0.0
var is_stunned: bool = false
var stun_timer: Timer

# Attack properties
var attack_cooldown: float = 2.0
var attack_timer: Timer
var can_attack: bool = true
var damage_flash_duration: float = 0.2

# Property aliases for compatibility
var health: int:
	get:
		return current_health
	set(value):
		current_health = value

var attack_damage: int:
	get:
		return attack_power
	set(value):
		attack_power = value

var detection_range: float:
	get:
		return detection_radius
	set(value):
		detection_radius = value

# Movement and pathfinding
var path_to_target: Array = []
var movement_target: Vector2
var stuck_check_timer: float = 0.0
var last_position: Vector2
var wander_timer: float = 0.0

# UI nodes
@onready var sprite = $Sprite2D
@onready var sprite_2d = $Sprite2D  # Alias for BlueWitch compatibility
@onready var health_bar = $HealthBar
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var hurt_box = $HurtBox

# Animation and effects
var original_modulate: Color = Color.WHITE

# Signals
signal enemy_died(enemy: Enemy)
signal enemy_spotted_player(enemy: Enemy, player: Node)
signal enemy_lost_player(enemy: Enemy)

func _ready():
	print("Enemy initialized: ", enemy_name)
	
	# Set spawn position
	spawn_position = global_position
	patrol_target = spawn_position
	last_position = global_position
	
	# Create timers
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)
	
	stun_timer = Timer.new()
	stun_timer.one_shot = true
	stun_timer.timeout.connect(_on_stun_timer_timeout)
	add_child(stun_timer)
	
	# Set up detection area
	if detection_area:
		var detection_shape = CircleShape2D.new()
		detection_shape.radius = detection_radius
		detection_area.get_child(0).shape = detection_shape
	
	# Set up attack area
	if attack_area:
		var attack_shape = CircleShape2D.new()
		attack_shape.radius = attack_range
		attack_area.get_child(0).shape = attack_shape
	
	# Connect signals
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		attack_area.body_exited.connect(_on_attack_area_body_exited)
	
	# Set up health bar
	update_health_bar()
	
	# Store original sprite color
	if sprite:
		original_modulate = sprite.modulate
	
	# Start AI
	current_state = EnemyState.IDLE
	
	# Add to enemies group
	add_to_group("enemies")

func _physics_process(delta):
	if current_state == EnemyState.DEAD:
		return
	
	# Update state timer
	state_timer += delta
	
	# Handle AI state machine
	match current_state:
		EnemyState.IDLE:
			handle_idle_state(delta)
		EnemyState.PATROL:
			handle_patrol_state(delta)
		EnemyState.CHASE:
			handle_chase_state(delta)
		EnemyState.ATTACK:
			handle_attack_state(delta)
		EnemyState.STUNNED:
			handle_stunned_state(delta)
	
	# Check if stuck
	check_if_stuck(delta)
	
	# Move and slide
	move_and_slide()

func handle_idle_state(delta):
	# Look for players
	find_nearest_player()
	
	# Wander occasionally
	wander_timer += delta
	if wander_timer > 3.0:
		wander_timer = 0.0
		change_state(EnemyState.PATROL)

func handle_patrol_state(delta):
	# Check for players
	if target_player:
		change_state(EnemyState.CHASE)
		return
	
	# Move toward patrol target
	var direction = (patrol_target - global_position).normalized()
	velocity = direction * (move_speed * 0.5)  # Slower patrol speed
	
	# Check if reached patrol target
	if global_position.distance_to(patrol_target) < 20.0:
		# Pick new patrol target
		var angle = randf() * 2.0 * PI
		var distance = randf_range(20.0, patrol_radius)
		patrol_target = spawn_position + Vector2(cos(angle), sin(angle)) * distance
		
		# Sometimes return to idle
		if randf() < 0.3:
			change_state(EnemyState.IDLE)

func handle_chase_state(delta):
	if not target_player or not is_instance_valid(target_player):
		change_state(EnemyState.IDLE)
		return
	
	# Check if player is still in detection range
	var distance_to_player = global_position.distance_to(target_player.global_position)
	if distance_to_player > detection_radius * 1.5:  # Give some buffer
		target_player = null
		change_state(EnemyState.PATROL)
		return
	
	# Check if close enough to attack
	if distance_to_player <= attack_range:
		change_state(EnemyState.ATTACK)
		return
	
	# Move toward player
	var direction = (target_player.global_position - global_position).normalized()
	velocity = direction * move_speed
	
	# Update last known position
	last_known_player_position = target_player.global_position

func handle_attack_state(delta):
	if not target_player or not is_instance_valid(target_player):
		change_state(EnemyState.IDLE)
		return
	
	# Check if player moved out of attack range
	var distance_to_player = global_position.distance_to(target_player.global_position)
	if distance_to_player > attack_range:
		change_state(EnemyState.CHASE)
		return
	
	# Stop moving during attack
	velocity = Vector2.ZERO
	
	# Attack if cooldown is ready
	if can_attack:
		perform_attack()

func handle_stunned_state(delta):
	# Can't move or attack while stunned
	velocity = Vector2.ZERO

func change_state(new_state: EnemyState):
	if current_state == new_state:
		return
	
	print("Enemy ", enemy_name, " changing state: ", EnemyState.find_key(current_state), " -> ", EnemyState.find_key(new_state))
	
	# Exit current state
	match current_state:
		EnemyState.CHASE:
			if new_state != EnemyState.ATTACK:
				enemy_lost_player.emit(self)
	
	# Enter new state
	current_state = new_state
	state_timer = 0.0
	
	match new_state:
		EnemyState.IDLE:
			velocity = Vector2.ZERO
		EnemyState.PATROL:
			if patrol_target == Vector2.ZERO:
				patrol_target = spawn_position
		EnemyState.CHASE:
			if target_player:
				enemy_spotted_player.emit(self, target_player)
		EnemyState.ATTACK:
			velocity = Vector2.ZERO

func find_nearest_player():
	var players = get_tree().get_nodes_in_group("players")
	var nearest_player = null
	var min_distance = detection_radius
	
	for player in players:
		if player.has_method("take_damage") and player.current_state != Player.PlayerState.DEAD:
			var distance = global_position.distance_to(player.global_position)
			if distance < min_distance:
				nearest_player = player
				min_distance = distance
	
	if nearest_player != target_player:
		target_player = nearest_player
		if target_player:
			change_state(EnemyState.CHASE)

func perform_attack():
	if not target_player or not can_attack:
		return
	
	print("Enemy ", enemy_name, " attacking player!")
	
	# Deal damage to player
	if target_player.has_method("take_damage"):
		target_player.take_damage(attack_power, -1)  # -1 for enemy ID
	
	# Start attack cooldown
	can_attack = false
	attack_timer.start()
	
	# Create attack effect
	create_attack_effect()
	
	# Play attack animation/sound
	play_attack_animation()

func take_damage(damage: int, attacker_id: int = -1):
	if current_state == EnemyState.DEAD:
		return
	
	current_health -= damage
	current_health = max(0, current_health)
	
	print("Enemy ", enemy_name, " took ", damage, " damage. Health: ", current_health, "/", max_health)
	
	# Update health bar
	update_health_bar()
	
	# Flash red when taking damage
	create_damage_flash()
	
	# Interrupt current action
	if current_state == EnemyState.IDLE or current_state == EnemyState.PATROL:
		# Look for the attacker
		if attacker_id != -1:
			var attacker = find_player_by_id(attacker_id)
			if attacker:
				target_player = attacker
				change_state(EnemyState.CHASE)
	
	# Check for death
	if current_health <= 0:
		die()

func die():
	if current_state == EnemyState.DEAD:
		return
	
	print("Enemy ", enemy_name, " died!")
	
	current_state = EnemyState.DEAD
	
	# Stop all movement
	velocity = Vector2.ZERO
	
	# Play death animation
	play_death_animation()
	
	# Emit signal
	enemy_died.emit(self)
	
	# Update game stats
	GameManager.update_stat("enemies_killed", 1)
	
	# Remove from collision
	set_collision_layer_value(2, false)
	set_collision_mask_value(1, false)
	
	# Clean up after delay
	await get_tree().create_timer(2.0).timeout
	queue_free()

func stun(duration: float):
	if current_state == EnemyState.DEAD:
		return
	
	is_stunned = true
	change_state(EnemyState.STUNNED)
	
	# Visual effect
	sprite.modulate = Color.YELLOW
	
	# Set stun timer
	stun_timer.wait_time = duration
	stun_timer.start()
	
	print("Enemy ", enemy_name, " stunned for ", duration, " seconds")

func apply_knockback(direction: Vector2, force: float):
	# Apply knockback force
	velocity = direction * force
	
	# Brief stun during knockback
	stun(0.3)

func heal(amount: int):
	current_health = min(max_health, current_health + amount)
	update_health_bar()
	print("Enemy ", enemy_name, " healed for ", amount, ". Health: ", current_health, "/", max_health)

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

func create_damage_flash():
	if sprite:
		# Flash red
		sprite.modulate = Color.RED
		
		# Return to normal color
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", original_modulate, damage_flash_duration)

func create_attack_effect():
	# Create simple attack effect
	var effect = ColorRect.new()
	effect.size = Vector2(24, 24)
	effect.color = Color(1.0, 0.5, 0.0, 0.8)  # Orange attack effect
	effect.position = sprite.position - Vector2(12, 12)
	add_child(effect)
	
	# Animate effect
	var tween = create_tween()
	tween.tween_property(effect, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(effect, "modulate", Color.TRANSPARENT, 0.2)
	tween.tween_callback(effect.queue_free)

func play_attack_animation():
	# Simple attack animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)

func play_death_animation():
	# Death animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.TRANSPARENT, 1.0)
		tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 1.0)

func check_if_stuck(delta):
	# Check if enemy is stuck
	stuck_check_timer += delta
	if stuck_check_timer >= 1.0:
		var distance_moved = global_position.distance_to(last_position)
		if distance_moved < 10.0 and velocity.length() > 0:
			# Enemy is stuck, try to unstuck
			unstuck()
		
		last_position = global_position
		stuck_check_timer = 0.0

func unstuck():
	# Try to find a new path or target
	if current_state == EnemyState.PATROL:
		# Pick new patrol target
		var angle = randf() * 2.0 * PI
		var distance = randf_range(30.0, patrol_radius)
		patrol_target = spawn_position + Vector2(cos(angle), sin(angle)) * distance
	elif current_state == EnemyState.CHASE and target_player:
		# Try to move around obstacle
		var to_player = (target_player.global_position - global_position).normalized()
		var perpendicular = Vector2(-to_player.y, to_player.x)
		velocity = perpendicular * move_speed * 0.5

func find_player_by_id(player_id: int) -> Node:
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player.has_method("get") and player.player_id == player_id:
			return player
	return null

# Signal handlers
func _on_detection_area_body_entered(body):
	if body.is_in_group("players") and body.has_method("take_damage"):
		if body.current_state != Player.PlayerState.DEAD:
			target_player = body
			change_state(EnemyState.CHASE)

func _on_detection_area_body_exited(body):
	if body == target_player:
		# Don't immediately lose target, give some buffer
		await get_tree().create_timer(1.0).timeout
		if target_player == body:
			target_player = null
			change_state(EnemyState.PATROL)

func _on_attack_area_body_entered(body):
	if body == target_player and current_state == EnemyState.CHASE:
		change_state(EnemyState.ATTACK)

func _on_attack_area_body_exited(body):
	if body == target_player and current_state == EnemyState.ATTACK:
		change_state(EnemyState.CHASE)

func _on_attack_timer_timeout():
	can_attack = true

func _on_stun_timer_timeout():
	is_stunned = false
	sprite.modulate = original_modulate
	change_state(EnemyState.IDLE)

# Utility functions
func get_state_name() -> String:
	return EnemyState.find_key(current_state)

func get_distance_to_spawn() -> float:
	return global_position.distance_to(spawn_position)

func get_distance_to_player() -> float:
	if target_player:
		return global_position.distance_to(target_player.global_position)
	return -1.0

func is_player_visible(player: Node) -> bool:
	# Simple line of sight check
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	
	return result.is_empty() or result.collider == player

# Override this in derived classes for specific enemy behaviors
func get_enemy_description() -> String:
	return "Basic Enemy"

func get_loot_drops() -> Array:
	return []  # Override in derived classes

func apply_status_effect(effect_name: String, damage: int, duration: float):
	# Handle status effects like poison
	match effect_name:
		"poison":
			apply_poison(damage, duration)
		"burn":
			apply_burn(damage, duration)
		"freeze":
			apply_freeze(duration)

func apply_poison(damage: int, duration: float):
	# Apply poison damage over time
	var poison_ticks = int(duration)
	for i in range(poison_ticks):
		await get_tree().create_timer(1.0).timeout
		if current_state != EnemyState.DEAD:
			take_damage(damage, -1)
			create_poison_effect()

func apply_burn(damage: int, duration: float):
	# Apply burn damage over time
	var burn_ticks = int(duration)
	for i in range(burn_ticks):
		await get_tree().create_timer(1.0).timeout
		if current_state != EnemyState.DEAD:
			take_damage(damage, -1)
			create_burn_effect()

func apply_freeze(duration: float):
	# Freeze enemy (can't move or attack)
	stun(duration)
	sprite.modulate = Color.CYAN

func create_poison_effect():
	# Visual poison effect
	var poison = ColorRect.new()
	poison.size = Vector2(8, 8)
	poison.color = Color.GREEN
	poison.position = sprite.position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	add_child(poison)
	
	var tween = create_tween()
	tween.tween_property(poison, "position", poison.position + Vector2(0, -15), 0.5)
	tween.tween_property(poison, "modulate", Color.TRANSPARENT, 0.5)
	tween.tween_callback(poison.queue_free)

func create_burn_effect():
	# Visual burn effect
	var burn = ColorRect.new()
	burn.size = Vector2(8, 8)
	burn.color = Color.RED
	burn.position = sprite.position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	add_child(burn)
	
	var tween = create_tween()
	tween.tween_property(burn, "position", burn.position + Vector2(0, -15), 0.5)
	tween.tween_property(burn, "modulate", Color.TRANSPARENT, 0.5)
	tween.tween_callback(burn.queue_free) 