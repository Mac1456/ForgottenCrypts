extends Enemy
class_name SkeletonGrunt

# Skeleton grunt specific properties
var bone_throw_range: float = 80.0
var bone_throw_damage: int = 15
var bone_throw_cooldown: float = 4.0
var bone_throw_timer: Timer
var can_throw_bone: bool = true

func _ready():
	# Set enemy type and properties
	enemy_type = EnemyType.SKELETON_GRUNT
	enemy_name = "Skeleton Grunt"
	max_health = 40
	current_health = max_health
	attack_power = 18
	move_speed = 70
	detection_radius = 100.0
	attack_range = 35.0
	attack_cooldown = 2.5
	
	# Create bone throw timer
	bone_throw_timer = Timer.new()
	bone_throw_timer.wait_time = bone_throw_cooldown
	bone_throw_timer.one_shot = true
	bone_throw_timer.timeout.connect(_on_bone_throw_timer_timeout)
	add_child(bone_throw_timer)
	
	# Call parent ready
	super._ready()
	
	# Set sprite frame for skeleton (row 7, column 0)
	sprite.frame = 56  # 7*8 + 0
	
	print("Skeleton Grunt initialized")

func _physics_process(delta):
	super._physics_process(delta)
	
	# Check if can throw bone at player
	if current_state == EnemyState.CHASE and target_player and can_throw_bone:
		var distance_to_player = global_position.distance_to(target_player.global_position)
		if distance_to_player <= bone_throw_range and distance_to_player > attack_range:
			throw_bone_at_player()

func throw_bone_at_player():
	if not target_player or not can_throw_bone:
		return
	
	print("Skeleton Grunt throwing bone at player!")
	
	# Start cooldown
	can_throw_bone = false
	bone_throw_timer.start()
	
	# Create bone projectile
	var bone_projectile = create_bone_projectile()
	if bone_projectile:
		# Set projectile properties
		var direction = (target_player.global_position - global_position).normalized()
		bone_projectile.global_position = global_position
		bone_projectile.direction = direction
		bone_projectile.speed = 150.0
		bone_projectile.damage = bone_throw_damage
		
		# Add to game world
		get_parent().add_child(bone_projectile)
	
	# Create throw effect
	create_bone_throw_effect()

func create_bone_projectile():
	# Create simple bone projectile
	var bone = RigidBody2D.new()
	bone.name = "BoneProjectile"
	bone.gravity_scale = 0.0
	
	# Add sprite
	var bone_sprite = Sprite2D.new()
	bone_sprite.texture = sprite.texture
	bone_sprite.hframes = 8
	bone_sprite.vframes = 8
	bone_sprite.frame = 32  # Bone/arrow frame
	bone.add_child(bone_sprite)
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(8, 8)
	collision.shape = shape
	bone.add_child(collision)
	
	# Add movement script
	var script_code = """
extends RigidBody2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 150.0
var damage: int = 15
var lifetime: float = 3.0

func _ready():
	# Set up collision
	collision_layer = 4
	collision_mask = 1
	
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
	effect.size = Vector2(16, 16)
	effect.color = Color.YELLOW
	effect.global_position = global_position - Vector2(8, 8)
	get_parent().add_child(effect)
	
	var tween = effect.create_tween()
	tween.tween_property(effect, 'scale', Vector2(1.5, 1.5), 0.2)
	tween.tween_property(effect, 'modulate', Color.TRANSPARENT, 0.2)
	tween.tween_callback(effect.queue_free)

func get_damage() -> int:
	return damage
"""
	
	# Create and attach script
	var bone_script = GDScript.new()
	bone_script.source_code = script_code
	bone.set_script(bone_script)
	
	return bone

func create_bone_throw_effect():
	# Create throw effect
	var effect = ColorRect.new()
	effect.size = Vector2(20, 20)
	effect.color = Color(0.9, 0.9, 0.7, 0.8)  # Bone color
	effect.position = sprite.position - Vector2(10, 10)
	add_child(effect)
	
	# Animate effect
	var tween = create_tween()
	tween.tween_property(effect, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(effect, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(effect.queue_free)

# Override attack for skeleton-specific behavior
func perform_attack():
	if not target_player or not can_attack:
		return
	
	print("Skeleton Grunt performing claw attack!")
	
	# Deal damage to player
	if target_player.has_method("take_damage"):
		target_player.take_damage(attack_power, -1)
	
	# Start attack cooldown
	can_attack = false
	attack_timer.start()
	
	# Create skeleton claw effect
	create_skeleton_claw_effect()
	
	# Play attack animation
	play_skeleton_attack_animation()

func create_skeleton_claw_effect():
	# Create claw marks effect
	var claw_marks = []
	for i in range(3):
		var claw = ColorRect.new()
		claw.size = Vector2(16, 4)
		claw.color = Color(0.8, 0.8, 0.8, 0.9)  # Bone white
		claw.position = sprite.position + Vector2(-8, -6 + i * 4)
		claw.rotation = deg_to_rad(45)
		add_child(claw)
		claw_marks.append(claw)
	
	# Animate claw marks
	for claw in claw_marks:
		var tween = create_tween()
		tween.tween_property(claw, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(claw, "modulate", Color.TRANSPARENT, 0.2)
		tween.tween_callback(claw.queue_free)

func play_skeleton_attack_animation():
	# Skeleton attack animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.1, 1.1), 0.05)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.05)
		tween.tween_property(sprite, "rotation", deg_to_rad(5), 0.05)
		tween.tween_property(sprite, "rotation", deg_to_rad(0), 0.05)

# Override death animation for skeleton
func play_death_animation():
	# Skeleton death animation - bones scatter
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.TRANSPARENT, 0.8)
		tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.8)
		
		# Create bone scatter effect
		create_bone_scatter_effect()

func create_bone_scatter_effect():
	# Create scattered bones effect
	for i in range(5):
		var bone = ColorRect.new()
		bone.size = Vector2(6, 6)
		bone.color = Color(0.9, 0.9, 0.7)  # Bone color
		bone.global_position = global_position + Vector2(
			randf_range(-20, 20),
			randf_range(-20, 20)
		)
		
		get_parent().add_child(bone)
		
		# Animate bone
		var tween = create_tween()
		tween.tween_property(bone, "position", bone.position + Vector2(
			randf_range(-50, 50),
			randf_range(-50, 50)
		), 0.8)
		tween.tween_property(bone, "modulate", Color.TRANSPARENT, 0.8)
		tween.tween_callback(bone.queue_free)

# Override for skeleton-specific behavior
func handle_chase_state(delta):
	super.handle_chase_state(delta)
	
	# Skeleton grunts are more aggressive when chasing
	if target_player and state_timer > 1.0:
		# Increase speed when chasing for a while
		move_speed = 85

func handle_idle_state(delta):
	super.handle_idle_state(delta)
	
	# Skeletons occasionally make noise
	if randf() < 0.001:  # Very small chance each frame
		create_rattle_effect()

func create_rattle_effect():
	# Create bone rattle effect
	var rattle = ColorRect.new()
	rattle.size = Vector2(12, 12)
	rattle.color = Color(0.9, 0.9, 0.7, 0.6)
	rattle.position = sprite.position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	add_child(rattle)
	
	# Animate rattle
	var tween = create_tween()
	tween.tween_property(rattle, "scale", Vector2(0.5, 0.5), 0.2)
	tween.tween_property(rattle, "modulate", Color.TRANSPARENT, 0.2)
	tween.tween_callback(rattle.queue_free)

func _on_bone_throw_timer_timeout():
	can_throw_bone = true

# Override for skeleton-specific loot
func get_loot_drops() -> Array:
	var drops = []
	
	# Common drops
	if randf() < 0.3:
		drops.append({"type": "bone", "amount": 1})
	
	if randf() < 0.1:
		drops.append({"type": "small_health_potion", "amount": 1})
	
	return drops

func get_enemy_description() -> String:
	return "Skeleton Grunt: Basic undead warrior that attacks with claws and throws bones at distant enemies."

# Apply skeleton-specific damage resistance
func take_damage(damage: int, attacker_id: int = -1):
	# Skeletons take reduced damage from physical attacks
	var reduced_damage = damage
	
	# Check if damage is from magic (wizard abilities)
	if attacker_id != -1:
		var attacker = find_player_by_id(attacker_id)
		if attacker and attacker.character_type == ProgressionManager.CharacterType.WIZARD:
			# Normal damage from magic
			reduced_damage = damage
		else:
			# Reduced damage from physical attacks
			reduced_damage = int(damage * 0.85)
	
	super.take_damage(reduced_damage, attacker_id)

# Skeleton-specific stun resistance
func stun(duration: float):
	# Skeletons have shorter stun duration
	var reduced_duration = duration * 0.7
	super.stun(reduced_duration) 