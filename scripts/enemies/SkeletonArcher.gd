extends Enemy
class_name SkeletonArcher

# Skeleton archer specific properties
var bow_range: float = 200.0
var arrow_damage: int = 25
var arrow_speed: float = 250.0
var aim_time: float = 1.0
var is_aiming: bool = false
var aim_timer: Timer
var preferred_distance: float = 120.0  # Preferred distance from player

func _ready():
	# Set enemy type and properties
	enemy_type = EnemyType.SKELETON_ARCHER
	enemy_name = "Skeleton Archer"
	max_health = 35
	current_health = max_health
	attack_power = 8  # Low melee damage
	move_speed = 60
	detection_radius = 150.0
	attack_range = bow_range
	attack_cooldown = 3.0
	
	# Create aim timer
	aim_timer = Timer.new()
	aim_timer.wait_time = aim_time
	aim_timer.one_shot = true
	aim_timer.timeout.connect(_on_aim_timer_timeout)
	add_child(aim_timer)
	
	# Call parent ready
	super._ready()
	
	# Set sprite frame for skeleton archer (row 7, column 1)
	sprite.frame = 57  # 7*8 + 1
	
	print("Skeleton Archer initialized")

func _physics_process(delta):
	super._physics_process(delta)
	
	# Archer behavior: try to maintain distance from player
	if current_state == EnemyState.CHASE and target_player:
		var distance_to_player = global_position.distance_to(target_player.global_position)
		
		# If too close, try to back away
		if distance_to_player < preferred_distance * 0.7:
			var direction_away = (global_position - target_player.global_position).normalized()
			velocity = direction_away * move_speed
		# If too far, move closer (but not too close)
		elif distance_to_player > preferred_distance * 1.3:
			var direction_closer = (target_player.global_position - global_position).normalized()
			velocity = direction_closer * move_speed * 0.8
		else:
			# Good distance, stop moving and attack
			velocity = Vector2.ZERO
			if not is_aiming:
				change_state(EnemyState.ATTACK)

# Override attack for archer-specific behavior
func perform_attack():
	if not target_player or not can_attack:
		return
	
	if not is_aiming:
		start_aiming()
	else:
		fire_arrow()

func start_aiming():
	if is_aiming:
		return
	
	print("Skeleton Archer starting to aim!")
	
	is_aiming = true
	aim_timer.start()
	
	# Visual aiming effect
	create_aiming_effect()

func fire_arrow():
	if not target_player or not is_aiming:
		return
	
	print("Skeleton Archer firing arrow!")
	
	# Reset aiming
	is_aiming = false
	can_attack = false
	attack_timer.start()
	
	# Create arrow projectile
	var arrow = create_arrow_projectile()
	if arrow:
		# Set projectile properties
		var direction = (target_player.global_position - global_position).normalized()
		arrow.global_position = global_position
		arrow.direction = direction
		arrow.speed = arrow_speed
		arrow.damage = arrow_damage
		
		# Add to game world
		get_parent().add_child(arrow)
	
	# Create firing effect
	create_arrow_fire_effect()

func create_arrow_projectile():
	# Create arrow projectile
	var arrow = RigidBody2D.new()
	arrow.name = "ArrowProjectile"
	arrow.gravity_scale = 0.0
	
	# Add sprite
	var arrow_sprite = Sprite2D.new()
	arrow_sprite.texture = sprite.texture
	arrow_sprite.hframes = 8
	arrow_sprite.vframes = 8
	arrow_sprite.frame = 33  # Arrow frame
	arrow.add_child(arrow_sprite)
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(12, 4)
	collision.shape = shape
	arrow.add_child(collision)
	
	# Add movement script
	var script_code = """
extends RigidBody2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 250.0
var damage: int = 25
var lifetime: float = 4.0

func _ready():
	# Set up collision
	collision_layer = 4
	collision_mask = 1
	
	# Rotate to face direction
	if direction != Vector2.ZERO:
		rotation = direction.angle()
	
	# Set up lifetime
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()
	
	# Set up body entered signal
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	linear_velocity = direction * speed

func _on_body_entered(body):
	if body.has_method('take_damage'):
		body.take_damage(damage, -1)
		create_impact_effect()
		queue_free()

func create_impact_effect():
	var effect = ColorRect.new()
	effect.size = Vector2(12, 12)
	effect.color = Color(0.8, 0.6, 0.0, 0.8)  # Arrow color
	effect.global_position = global_position - Vector2(6, 6)
	get_parent().add_child(effect)
	
	var tween = effect.create_tween()
	tween.tween_property(effect, 'scale', Vector2(1.3, 1.3), 0.2)
	tween.tween_property(effect, 'modulate', Color.TRANSPARENT, 0.2)
	tween.tween_callback(effect.queue_free)

func get_damage() -> int:
	return damage
"""
	
	# Create and attach script
	var arrow_script = GDScript.new()
	arrow_script.source_code = script_code
	arrow.set_script(arrow_script)
	
	return arrow

func create_aiming_effect():
	# Create aiming sight line
	var sight_line = Line2D.new()
	sight_line.width = 2
	sight_line.default_color = Color.RED
	sight_line.name = "AimingSight"
	
	# Draw line from archer to player
	if target_player:
		sight_line.add_point(Vector2.ZERO)
		var to_player = target_player.global_position - global_position
		sight_line.add_point(to_player)
	
	add_child(sight_line)
	
	# Pulsing effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sight_line, "modulate", Color(1.0, 0.0, 0.0, 0.3), 0.3)
	tween.tween_property(sight_line, "modulate", Color(1.0, 0.0, 0.0, 0.8), 0.3)
	
	# Remove after aim time
	aim_timer.timeout.connect(sight_line.queue_free)

func create_arrow_fire_effect():
	# Create bow fire effect
	var fire_effect = ColorRect.new()
	fire_effect.size = Vector2(16, 16)
	fire_effect.color = Color(1.0, 0.8, 0.0, 0.8)  # Bow flash
	fire_effect.position = sprite.position - Vector2(8, 8)
	add_child(fire_effect)
	
	# Animate effect
	var tween = create_tween()
	tween.tween_property(fire_effect, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(fire_effect, "modulate", Color.TRANSPARENT, 0.2)
	tween.tween_callback(fire_effect.queue_free)

# Override chase state for archer behavior
func handle_chase_state(delta):
	if not target_player or not is_instance_valid(target_player):
		change_state(EnemyState.IDLE)
		return
	
	var distance_to_player = global_position.distance_to(target_player.global_position)
	
	# Check if player is still in detection range
	if distance_to_player > detection_radius * 1.5:
		target_player = null
		change_state(EnemyState.PATROL)
		return
	
	# Archer-specific positioning
	if distance_to_player < preferred_distance * 0.7:
		# Too close, back away
		var direction_away = (global_position - target_player.global_position).normalized()
		velocity = direction_away * move_speed
	elif distance_to_player > bow_range:
		# Too far, move closer
		var direction_closer = (target_player.global_position - global_position).normalized()
		velocity = direction_closer * move_speed
	else:
		# Good range, attack
		change_state(EnemyState.ATTACK)
	
	# Update last known position
	last_known_player_position = target_player.global_position

# Override attack state for archer behavior
func handle_attack_state(delta):
	if not target_player or not is_instance_valid(target_player):
		change_state(EnemyState.IDLE)
		return
	
	var distance_to_player = global_position.distance_to(target_player.global_position)
	
	# Check if player moved out of range
	if distance_to_player > bow_range:
		change_state(EnemyState.CHASE)
		return
	
	# Check if player is too close
	if distance_to_player < preferred_distance * 0.7:
		change_state(EnemyState.CHASE)
		return
	
	# Stop moving during attack
	velocity = Vector2.ZERO
	
	# Face the player
	if target_player.global_position.x < global_position.x:
		sprite.scale.x = -1
	else:
		sprite.scale.x = 1
	
	# Attack if cooldown is ready
	if can_attack:
		perform_attack()

func _on_aim_timer_timeout():
	if is_aiming:
		fire_arrow()

# Override for archer-specific loot
func get_loot_drops() -> Array:
	var drops = []
	
	# Common drops
	if randf() < 0.4:
		drops.append({"type": "arrow", "amount": randf_range(1, 3)})
	
	if randf() < 0.2:
		drops.append({"type": "bow_string", "amount": 1})
	
	if randf() < 0.1:
		drops.append({"type": "small_health_potion", "amount": 1})
	
	return drops

func get_enemy_description() -> String:
	return "Skeleton Archer: Ranged undead warrior that fires arrows and tries to maintain distance from enemies."

# Override for archer-specific damage resistance
func take_damage(damage: int, attacker_id: int = -1):
	# Archers are fragile - take extra damage
	var modified_damage = int(damage * 1.1)
	
	# Interrupt aiming if taking damage
	if is_aiming:
		is_aiming = false
		aim_timer.stop()
		
		# Remove aiming sight if it exists
		var sight = get_node_or_null("AimingSight")
		if sight:
			sight.queue_free()
	
	super.take_damage(modified_damage, attacker_id)

# Override death animation for archer
func play_death_animation():
	# Archer death animation - bow breaks
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.TRANSPARENT, 0.8)
		tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.8)
		
		# Create bow break effect
		create_bow_break_effect()

func create_bow_break_effect():
	# Create broken bow pieces
	for i in range(3):
		var piece = ColorRect.new()
		piece.size = Vector2(8, 4)
		piece.color = Color(0.6, 0.4, 0.2)  # Wood color
		piece.global_position = global_position + Vector2(
			randf_range(-10, 10),
			randf_range(-10, 10)
		)
		
		get_parent().add_child(piece)
		
		# Animate piece
		var tween = create_tween()
		tween.tween_property(piece, "position", piece.position + Vector2(
			randf_range(-30, 30),
			randf_range(-30, 30)
		), 0.6)
		tween.tween_property(piece, "modulate", Color.TRANSPARENT, 0.6)
		tween.tween_callback(piece.queue_free)

# Override stun for archer
func stun(duration: float):
	# Interrupt aiming when stunned
	if is_aiming:
		is_aiming = false
		aim_timer.stop()
		
		# Remove aiming sight if it exists
		var sight = get_node_or_null("AimingSight")
		if sight:
			sight.queue_free()
	
	super.stun(duration)

# Archer-specific AI behavior
func handle_idle_state(delta):
	super.handle_idle_state(delta)
	
	# Archers are more alert - scan for enemies more frequently
	if wander_timer > 2.0:
		wander_timer = 0.0
		find_nearest_player()

func handle_patrol_state(delta):
	super.handle_patrol_state(delta)
	
	# Archers patrol more cautiously
	var direction = (patrol_target - global_position).normalized()
	velocity = direction * (move_speed * 0.4)  # Even slower patrol speed 