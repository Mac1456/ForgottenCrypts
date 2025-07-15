extends "res://scripts/enemies/Enemy.gd"

# Boss phases
enum BossPhase {
	PHASE_1,
	PHASE_2,
	PHASE_3
}

# Boss configuration
const PHASE_1_HEALTH_THRESHOLD = 0.75
const PHASE_2_HEALTH_THRESHOLD = 0.35
const SPELL_COOLDOWN = 3.0
const MINION_SPAWN_COOLDOWN = 10.0
const TELEPORT_COOLDOWN = 8.0
const HEAL_COOLDOWN = 20.0

# Boss stats
var is_final_boss: bool = false
var current_phase: BossPhase = BossPhase.PHASE_1
var spell_cooldown_timer: float = 0.0
var minion_spawn_timer: float = 0.0
var teleport_timer: float = 0.0
var heal_timer: float = 0.0
var summoned_minions: Array = []
var max_minions: int = 3
var is_casting: bool = false
var cast_timer: float = 0.0

# Signals
signal phase_changed(new_phase: BossPhase)
signal boss_spell_cast(spell_name: String)
signal minion_summoned(minion_node: Node2D)

func _ready():
	super._ready()
	
	# Set boss properties
	max_health = 500 if is_final_boss else 300
	health = max_health
	attack_damage = 60 if is_final_boss else 40
	move_speed = 70
	detection_range = 350
	attack_range = 250
	
	# Setup visuals
	_setup_boss_visuals()
	
	print("Blue Witch Boss initialized - Final Boss: ", is_final_boss)

func _setup_boss_visuals():
	# Scale up the boss
	scale = Vector2(2.0, 2.0) if is_final_boss else Vector2(1.5, 1.5)
	
	# Set witch sprite
	if sprite_2d:
		sprite_2d.texture = load("res://assets/enemies/witch_boss/Blue_witch/B_witch_idle.png")
		sprite_2d.modulate = Color(0.8, 0.8, 1.2)  # Blue tint

func _process(delta):
	# Update timers
	spell_cooldown_timer = max(0, spell_cooldown_timer - delta)
	minion_spawn_timer = max(0, minion_spawn_timer - delta)
	teleport_timer = max(0, teleport_timer - delta)
	heal_timer = max(0, heal_timer - delta)
	
	# Handle casting
	if is_casting:
		cast_timer -= delta
		if cast_timer <= 0:
			_finish_casting()
			is_casting = false
	
	# Check phase transitions
	_check_phase_transitions()
	
	# Clean up dead minions
	_cleanup_dead_minions()

func _physics_process(delta):
	if is_casting:
		# Don't move while casting
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	super._physics_process(delta)

# Override state machine behavior
func _handle_state_chase():
	if target_player == null:
		change_state(EnemyState.IDLE)
		return
	
	var distance_to_player = global_position.distance_to(target_player.global_position)
	
	# If close enough, try to cast spell or attack
	if distance_to_player <= attack_range:
		if spell_cooldown_timer <= 0 and not is_casting:
			_choose_and_cast_spell()
		else:
			change_state(EnemyState.ATTACK)
	else:
		# Move towards player
		var direction = (target_player.global_position - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()

# Choose and cast appropriate spell
func _choose_and_cast_spell():
	if is_casting:
		return
	
	var spell_choices = []
	
	# Add available spells based on phase and cooldowns
	if minion_spawn_timer <= 0 and summoned_minions.size() < max_minions:
		spell_choices.append("summon_minions")
	
	if teleport_timer <= 0 and target_player != null:
		var distance = global_position.distance_to(target_player.global_position)
		if distance < 120:  # Only teleport if too close
			spell_choices.append("teleport")
	
	if heal_timer <= 0 and health < max_health * 0.5:
		spell_choices.append("heal")
	
	# Always available spells
	spell_choices.append("magic_blast")
	spell_choices.append("area_damage")
	
	if spell_choices.size() > 0:
		var chosen_spell = spell_choices[randi() % spell_choices.size()]
		_start_casting(chosen_spell)

# Start casting a spell
func _start_casting(spell_name: String):
	is_casting = true
	
	# Set cast time based on spell
	match spell_name:
		"magic_blast":
			cast_timer = 0.8
		"area_damage":
			cast_timer = 1.5
		"summon_minions":
			cast_timer = 2.5
		"teleport":
			cast_timer = 0.5
		"heal":
			cast_timer = 3.0
		_:
			cast_timer = 1.0
	
	# Show casting animation
	if sprite_2d:
		sprite_2d.texture = load("res://assets/enemies/witch_boss/Blue_witch/B_witch_charge.png")
		sprite_2d.modulate = Color(1.2, 1.2, 1.5)  # Brighter while casting
	
	# Store current spell
	set_meta("current_spell", spell_name)
	
	print("Blue Witch casting: ", spell_name)

# Finish casting the current spell
func _finish_casting():
	var spell_name = get_meta("current_spell", "")
	
	match spell_name:
		"magic_blast":
			_cast_magic_blast()
		"area_damage":
			_cast_area_damage()
		"summon_minions":
			_cast_summon_minions()
		"teleport":
			_cast_teleport()
		"heal":
			_cast_heal()
	
	# Reset spell cooldown
	spell_cooldown_timer = SPELL_COOLDOWN
	
	# Return to idle animation
	if sprite_2d:
		sprite_2d.texture = load("res://assets/enemies/witch_boss/Blue_witch/B_witch_idle.png")
		sprite_2d.modulate = Color(0.8, 0.8, 1.2)  # Back to normal tint
	
	# Emit signal
	boss_spell_cast.emit(spell_name)

# Cast magic blast (direct damage)
func _cast_magic_blast():
	if target_player == null:
		return
	
	var damage = 35
	var distance = global_position.distance_to(target_player.global_position)
	
	if distance <= attack_range:
		# Direct damage to player
		if target_player.has_method("take_damage"):
			target_player.take_damage(damage)
		
		# Create visual effect
		_create_magic_effect(target_player.global_position)
	
	print("Blue Witch cast Magic Blast")

# Cast area damage (damages all nearby players)
func _cast_area_damage():
	var damage = 25
	var effect_radius = 150
	
	# Find all players within radius
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player != null and is_instance_valid(player):
			var distance = global_position.distance_to(player.global_position)
			if distance <= effect_radius:
				if player.has_method("take_damage"):
					player.take_damage(damage)
				
				# Create visual effect
				_create_magic_effect(player.global_position)
	
	print("Blue Witch cast Area Damage")

# Cast summon minions
func _cast_summon_minions():
	var minions_to_spawn = min(max_minions - summoned_minions.size(), 2)
	
	for i in range(minions_to_spawn):
		var minion = _create_minion()
		if minion:
			summoned_minions.append(minion)
			minion_summoned.emit(minion)
	
	minion_spawn_timer = MINION_SPAWN_COOLDOWN
	print("Blue Witch summoned ", minions_to_spawn, " minions")

# Create a minion
func _create_minion() -> Node2D:
	var skeleton_scene = preload("res://scenes/enemies/SkeletonGrunt.tscn")
	var minion = skeleton_scene.instantiate()
	
	# Configure minion
	minion.max_health = 50
	minion.health = 50
	minion.attack_damage = 15
	minion.move_speed = 90
	minion.scale = Vector2(0.8, 0.8)
	minion.modulate = Color(0.7, 0.7, 1.0)  # Blue tint
	
	# Position around the boss
	var spawn_offset = Vector2(randf_range(-120, 120), randf_range(-120, 120))
	minion.global_position = global_position + spawn_offset
	
	# Add to scene
	get_parent().add_child(minion)
	minion.add_to_group("minions")
	
	# Connect minion death signal
	minion.enemy_died.connect(_on_minion_died)
	
	return minion

# Cast teleport
func _cast_teleport():
	if target_player == null:
		return
	
	# Teleport to a position around the player
	var teleport_positions = []
	for i in range(8):
		var angle = i * PI / 4
		var pos = target_player.global_position + Vector2(cos(angle), sin(angle)) * 180
		teleport_positions.append(pos)
	
	var new_position = teleport_positions[randi() % teleport_positions.size()]
	global_position = new_position
	
	# Create teleport effect
	_create_teleport_effect()
	
	teleport_timer = TELEPORT_COOLDOWN
	print("Blue Witch teleported")

# Cast heal
func _cast_heal():
	var heal_amount = int(max_health * 0.2)
	health = min(health + heal_amount, max_health)
	
	# Create heal effect
	_create_heal_effect()
	
	heal_timer = HEAL_COOLDOWN
	print("Blue Witch healed for ", heal_amount)

# Create magic effect at position
func _create_magic_effect(pos: Vector2):
	var effect = ColorRect.new()
	effect.color = Color(0.5, 0.5, 1.0, 0.8)
	effect.size = Vector2(50, 50)
	effect.position = pos - Vector2(25, 25)
	get_parent().add_child(effect)
	
	# Animate effect
	var tween = create_tween()
	tween.tween_property(effect, "modulate", Color(0.5, 0.5, 1.0, 0), 0.8)
	tween.tween_callback(effect.queue_free)

# Create teleport effect
func _create_teleport_effect():
	var effect = ColorRect.new()
	effect.color = Color(0.3, 0.3, 1.0, 0.6)
	effect.size = Vector2(80, 80)
	effect.position = global_position - Vector2(40, 40)
	get_parent().add_child(effect)
	
	# Animate effect
	var tween = create_tween()
	tween.tween_property(effect, "scale", Vector2(2.0, 2.0), 0.5)
	tween.parallel().tween_property(effect, "modulate", Color(0.3, 0.3, 1.0, 0), 0.5)
	tween.tween_callback(effect.queue_free)

# Create heal effect
func _create_heal_effect():
	var effect = ColorRect.new()
	effect.color = Color(0.3, 1.0, 0.3, 0.6)
	effect.size = Vector2(100, 100)
	effect.position = global_position - Vector2(50, 50)
	get_parent().add_child(effect)
	
	# Animate effect
	var tween = create_tween()
	tween.tween_property(effect, "scale", Vector2(1.5, 1.5), 1.0)
	tween.parallel().tween_property(effect, "modulate", Color(0.3, 1.0, 0.3, 0), 1.0)
	tween.tween_callback(effect.queue_free)

# Check phase transitions
func _check_phase_transitions():
	var health_percentage = float(health) / float(max_health)
	
	if current_phase == BossPhase.PHASE_1 and health_percentage <= PHASE_1_HEALTH_THRESHOLD:
		_transition_to_phase(BossPhase.PHASE_2)
	elif current_phase == BossPhase.PHASE_2 and health_percentage <= PHASE_2_HEALTH_THRESHOLD:
		_transition_to_phase(BossPhase.PHASE_3)

# Transition to new phase
func _transition_to_phase(new_phase: BossPhase):
	current_phase = new_phase
	phase_changed.emit(new_phase)
	
	# Reset cooldowns for phase transition
	spell_cooldown_timer = 0
	
	# Increase difficulty
	match new_phase:
		BossPhase.PHASE_2:
			max_minions = 4
			move_speed = 80
			attack_damage += 10
			print("Blue Witch entered Phase 2!")
		BossPhase.PHASE_3:
			max_minions = 6
			move_speed = 90
			attack_damage += 15
			print("Blue Witch entered Phase 3!")

# Clean up dead minions
func _cleanup_dead_minions():
	for i in range(summoned_minions.size() - 1, -1, -1):
		var minion = summoned_minions[i]
		if minion == null or not is_instance_valid(minion):
			summoned_minions.remove_at(i)

# Override take damage to add boss mechanics
func take_damage(damage_amount: int, source_player_id: int = -1):
	# Boss has damage resistance
	var actual_damage = int(damage_amount * 0.8)  # 20% damage reduction
	
	# Boss has a chance to teleport when taking damage
	if current_phase >= BossPhase.PHASE_2 and teleport_timer <= 0:
		if randf() < 0.25:  # 25% chance
			_cast_teleport()
	
	super.take_damage(actual_damage, source_player_id)

# Initialize as final boss
func initialize_as_final_boss():
	is_final_boss = true
	max_health = 750
	health = max_health
	attack_damage = 70
	max_minions = 8
	scale = Vector2(2.5, 2.5)
	print("Blue Witch initialized as Final Boss")

# Signal handlers
func _on_minion_died(minion_node: Node2D):
	print("Boss minion died: ", minion_node.name)
	if minion_node in summoned_minions:
		summoned_minions.erase(minion_node)

# Get current phase
func get_current_phase() -> BossPhase:
	return current_phase

# Get summoned minions count
func get_minion_count() -> int:
	return summoned_minions.size()

# Check if boss is in final phase
func is_final_phase() -> bool:
	return current_phase == BossPhase.PHASE_3 