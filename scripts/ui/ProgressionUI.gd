extends Control

# UI Node references
@onready var wizard_button = $MainContainer/ContentContainer/CharacterList/CharacterButtons/WizardButton
@onready var barbarian_button = $MainContainer/ContentContainer/CharacterList/CharacterButtons/BarbarianButton
@onready var rogue_button = $MainContainer/ContentContainer/CharacterList/CharacterButtons/RogueButton
@onready var knight_button = $MainContainer/ContentContainer/CharacterList/CharacterButtons/KnightButton

@onready var character_name = $MainContainer/ContentContainer/DetailsContainer/CharacterDetails/CharacterName
@onready var health_label = $MainContainer/ContentContainer/DetailsContainer/CharacterDetails/CharacterStats/HealthLabel
@onready var attack_label = $MainContainer/ContentContainer/DetailsContainer/CharacterDetails/CharacterStats/AttackLabel
@onready var speed_label = $MainContainer/ContentContainer/DetailsContainer/CharacterDetails/CharacterStats/SpeedLabel
@onready var mana_label = $MainContainer/ContentContainer/DetailsContainer/CharacterDetails/CharacterStats/ManaLabel

@onready var level_label = $MainContainer/ContentContainer/DetailsContainer/CharacterDetails/ExperienceInfo/LevelLabel
@onready var experience_label = $MainContainer/ContentContainer/DetailsContainer/CharacterDetails/ExperienceInfo/ExperienceLabel
@onready var experience_bar = $MainContainer/ContentContainer/DetailsContainer/CharacterDetails/ExperienceInfo/ExperienceBar
@onready var skill_points_label = $MainContainer/ContentContainer/DetailsContainer/CharacterDetails/ExperienceInfo/SkillPointsLabel

@onready var health_upgrade_button = $MainContainer/ContentContainer/DetailsContainer/UpgradeSection/UpgradesList/HealthUpgrade/HealthUpgradeButton
@onready var attack_upgrade_button = $MainContainer/ContentContainer/DetailsContainer/UpgradeSection/UpgradesList/AttackUpgrade/AttackUpgradeButton
@onready var speed_upgrade_button = $MainContainer/ContentContainer/DetailsContainer/UpgradeSection/UpgradesList/SpeedUpgrade/SpeedUpgradeButton
@onready var mana_upgrade_button = $MainContainer/ContentContainer/DetailsContainer/UpgradeSection/UpgradesList/ManaUpgrade/ManaUpgradeButton
@onready var ability_upgrade_button = $MainContainer/ContentContainer/DetailsContainer/UpgradeSection/UpgradesList/AbilityUpgrade/AbilityUpgradeButton

@onready var back_button = $MainContainer/ButtonContainer/BackButton
@onready var play_button = $MainContainer/ButtonContainer/PlayButton

# Current selected character
var selected_character: ProgressionManager.CharacterType = ProgressionManager.CharacterType.WIZARD

# Character buttons mapping
var character_buttons: Dictionary = {}

# Signals
signal character_selected(character_type: ProgressionManager.CharacterType)
signal upgrade_purchased(character_type: ProgressionManager.CharacterType, upgrade_type: String)
signal progression_ui_closed()

func _ready():
	print("ProgressionUI initialized")
	
	# Setup character buttons
	character_buttons = {
		ProgressionManager.CharacterType.WIZARD: wizard_button,
		ProgressionManager.CharacterType.BARBARIAN: barbarian_button,
		ProgressionManager.CharacterType.ROGUE: rogue_button,
		ProgressionManager.CharacterType.KNIGHT: knight_button
	}
	
	# Connect character selection buttons
	wizard_button.pressed.connect(_on_character_selected.bind(ProgressionManager.CharacterType.WIZARD))
	barbarian_button.pressed.connect(_on_character_selected.bind(ProgressionManager.CharacterType.BARBARIAN))
	rogue_button.pressed.connect(_on_character_selected.bind(ProgressionManager.CharacterType.ROGUE))
	knight_button.pressed.connect(_on_character_selected.bind(ProgressionManager.CharacterType.KNIGHT))
	
	# Connect upgrade buttons
	health_upgrade_button.pressed.connect(_on_upgrade_purchased.bind("health"))
	attack_upgrade_button.pressed.connect(_on_upgrade_purchased.bind("attack"))
	speed_upgrade_button.pressed.connect(_on_upgrade_purchased.bind("speed"))
	mana_upgrade_button.pressed.connect(_on_upgrade_purchased.bind("mana"))
	ability_upgrade_button.pressed.connect(_on_upgrade_purchased.bind("ability"))
	
	# Connect navigation buttons
	back_button.pressed.connect(_on_back_pressed)
	play_button.pressed.connect(_on_play_pressed)
	
	# Connect to progression manager signals
	ProgressionManager.experience_gained.connect(_on_experience_gained)
	ProgressionManager.level_up.connect(_on_level_up)
	ProgressionManager.skill_point_gained.connect(_on_skill_point_gained)
	ProgressionManager.upgrade_purchased.connect(_on_upgrade_applied)
	
	# Update UI
	update_all_ui()

func _on_character_selected(character_type: ProgressionManager.CharacterType):
	selected_character = character_type
	character_selected.emit(character_type)
	
	# Update button states
	_update_character_button_states()
	
	# Update character details
	_update_character_details()
	
	print("Character selected: ", ProgressionManager.CharacterType.find_key(character_type))

func _on_upgrade_purchased(upgrade_type: String):
	var character_data = ProgressionManager.get_character_data(selected_character)
	var skill_points = character_data.get("skill_points", 0)
	
	# Check if player has enough skill points
	var required_points = _get_upgrade_cost(upgrade_type)
	if skill_points < required_points:
		print("Not enough skill points for upgrade: ", upgrade_type)
		return
	
	# Check if upgrade is already maxed
	if _is_upgrade_maxed(upgrade_type):
		print("Upgrade already maxed: ", upgrade_type)
		return
	
	# Apply upgrade
	var success = ProgressionManager.purchase_upgrade(selected_character, upgrade_type)
	if success:
		upgrade_purchased.emit(selected_character, upgrade_type)
		_update_character_details()
		print("Upgrade purchased: ", upgrade_type)
	else:
		print("Failed to purchase upgrade: ", upgrade_type)

func _on_back_pressed():
	print("Back to main menu")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_play_pressed():
	print("Continue playing")
	progression_ui_closed.emit()
	hide()

# Update all UI elements
func update_all_ui():
	_update_character_button_states()
	_update_character_details()
	_update_character_button_text()

# Update character button states
func _update_character_button_states():
	for character_type in character_buttons:
		var button = character_buttons[character_type]
		if character_type == selected_character:
			button.disabled = true
			button.modulate = Color(0.8, 0.8, 0.8)
		else:
			button.disabled = false
			button.modulate = Color.WHITE

# Update character button text with level info
func _update_character_button_text():
	for character_type in character_buttons:
		var button = character_buttons[character_type]
		var character_data = ProgressionManager.get_character_data(character_type)
		var character_name = character_data.get("name", "Unknown")
		var level = character_data.get("level", 1)
		button.text = "%s (Level %d)" % [character_name, level]

# Update character details display
func _update_character_details():
	var character_data = ProgressionManager.get_character_data(selected_character)
	
	# Update basic info
	character_name.text = character_data.get("name", "Unknown")
	
	# Update stats
	var stats = character_data.get("stats", {})
	health_label.text = "Health: %d" % stats.get("max_health", 100)
	attack_label.text = "Attack: %d" % stats.get("attack_power", 50)
	speed_label.text = "Speed: %d" % stats.get("move_speed", 100)
	mana_label.text = "Mana: %d" % stats.get("mana", 80)
	
	# Update experience info
	var level = character_data.get("level", 1)
	var experience = character_data.get("experience", 0)
	var skill_points = character_data.get("skill_points", 0)
	
	level_label.text = "Level: %d" % level
	
	# Calculate experience for next level
	var next_level_exp = ProgressionManager.get_experience_for_level(level + 1)
	var current_level_exp = ProgressionManager.get_experience_for_level(level)
	var exp_needed = next_level_exp - current_level_exp
	var exp_progress = experience - current_level_exp
	
	experience_label.text = "Experience: %d / %d" % [exp_progress, exp_needed]
	experience_bar.max_value = exp_needed
	experience_bar.value = exp_progress
	
	skill_points_label.text = "Skill Points: %d" % skill_points
	
	# Update upgrade buttons
	_update_upgrade_buttons()

# Update upgrade button states
func _update_upgrade_buttons():
	var character_data = ProgressionManager.get_character_data(selected_character)
	var skill_points = character_data.get("skill_points", 0)
	
	# Health upgrade
	var health_cost = _get_upgrade_cost("health")
	health_upgrade_button.disabled = skill_points < health_cost or _is_upgrade_maxed("health")
	health_upgrade_button.text = "Upgrade (%d SP)" % health_cost if not _is_upgrade_maxed("health") else "MAXED"
	
	# Attack upgrade
	var attack_cost = _get_upgrade_cost("attack")
	attack_upgrade_button.disabled = skill_points < attack_cost or _is_upgrade_maxed("attack")
	attack_upgrade_button.text = "Upgrade (%d SP)" % attack_cost if not _is_upgrade_maxed("attack") else "MAXED"
	
	# Speed upgrade
	var speed_cost = _get_upgrade_cost("speed")
	speed_upgrade_button.disabled = skill_points < speed_cost or _is_upgrade_maxed("speed")
	speed_upgrade_button.text = "Upgrade (%d SP)" % speed_cost if not _is_upgrade_maxed("speed") else "MAXED"
	
	# Mana upgrade
	var mana_cost = _get_upgrade_cost("mana")
	mana_upgrade_button.disabled = skill_points < mana_cost or _is_upgrade_maxed("mana")
	mana_upgrade_button.text = "Upgrade (%d SP)" % mana_cost if not _is_upgrade_maxed("mana") else "MAXED"
	
	# Ability upgrade
	var ability_cost = _get_upgrade_cost("ability")
	var third_ability_unlocked = character_data.get("third_ability_unlocked", false)
	ability_upgrade_button.disabled = skill_points < ability_cost or third_ability_unlocked
	ability_upgrade_button.text = "Unlock (%d SP)" % ability_cost if not third_ability_unlocked else "UNLOCKED"

# Get upgrade cost
func _get_upgrade_cost(upgrade_type: String) -> int:
	match upgrade_type:
		"health", "attack", "speed", "mana":
			return 1
		"ability":
			return 3
		_:
			return 1

# Check if upgrade is maxed
func _is_upgrade_maxed(upgrade_type: String) -> bool:
	var character_data = ProgressionManager.get_character_data(selected_character)
	var upgrades = character_data.get("upgrades", {})
	
	match upgrade_type:
		"health", "attack", "speed", "mana":
			return upgrades.get(upgrade_type, 0) >= 10  # Max 10 upgrades
		"ability":
			return character_data.get("third_ability_unlocked", false)
		_:
			return false

# Signal handlers
func _on_experience_gained(character_type: ProgressionManager.CharacterType, amount: int):
	print("Experience gained: ", ProgressionManager.CharacterType.find_key(character_type), " +", amount)
	if character_type == selected_character:
		_update_character_details()
	_update_character_button_text()

func _on_level_up(character_type: ProgressionManager.CharacterType, new_level: int):
	print("Level up: ", ProgressionManager.CharacterType.find_key(character_type), " -> Level ", new_level)
	if character_type == selected_character:
		_update_character_details()
	_update_character_button_text()

func _on_skill_point_gained(character_type: ProgressionManager.CharacterType, points: int):
	print("Skill points gained: ", ProgressionManager.CharacterType.find_key(character_type), " +", points)
	if character_type == selected_character:
		_update_character_details()

func _on_upgrade_applied(character_type: ProgressionManager.CharacterType, upgrade_type: String):
	print("Upgrade applied: ", ProgressionManager.CharacterType.find_key(character_type), " - ", upgrade_type)
	if character_type == selected_character:
		_update_character_details()

# Show progression UI
func show_progression_ui():
	show()
	update_all_ui()

# Hide progression UI
func hide_progression_ui():
	hide()
	progression_ui_closed.emit()

# Get current selected character
func get_selected_character() -> ProgressionManager.CharacterType:
	return selected_character

# Set selected character
func set_selected_character(character_type: ProgressionManager.CharacterType):
	selected_character = character_type
	update_all_ui()

# Award experience to all characters (called after level completion)
func award_level_experience(amount: int):
	ProgressionManager.award_experience(amount)
	update_all_ui()

# Check if any character has skill points to spend
func has_skill_points_to_spend() -> bool:
	for character_type in ProgressionManager.CharacterType.values():
		var character_data = ProgressionManager.get_character_data(character_type)
		if character_data.get("skill_points", 0) > 0:
			return true
	return false

# Get total progression stats
func get_progression_stats() -> Dictionary:
	var stats = {
		"total_levels": 0,
		"total_experience": 0,
		"total_skill_points": 0,
		"total_upgrades": 0
	}
	
	for character_type in ProgressionManager.CharacterType.values():
		var character_data = ProgressionManager.get_character_data(character_type)
		stats["total_levels"] += character_data.get("level", 1)
		stats["total_experience"] += character_data.get("total_experience", 0)
		stats["total_skill_points"] += character_data.get("skill_points", 0)
		
		var upgrades = character_data.get("upgrades", {})
		for upgrade_type in upgrades:
			stats["total_upgrades"] += upgrades[upgrade_type]
	
	return stats 