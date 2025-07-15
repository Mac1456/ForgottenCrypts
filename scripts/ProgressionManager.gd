extends Node

# Save file path
const SAVE_FILE_PATH = "user://progression_save.dat"

# Character types
enum CharacterType {
	WIZARD,
	BARBARIAN,
	ROGUE,
	KNIGHT
}

# Character data structure
var character_data = {
	CharacterType.WIZARD: {
		"name": "Wizard",
		"level": 1,
		"experience": 0,
		"total_experience": 0,
		"skill_points": 0,
		"upgrades": {},
		"abilities_unlocked": ["fireball", "magic_missile"],
		"third_ability_unlocked": false,
		"stats": {
			"max_health": 80,
			"attack_power": 90,
			"move_speed": 110,
			"mana": 120,
			"magic_resistance": 80
		}
	},
	CharacterType.BARBARIAN: {
		"name": "Barbarian",
		"level": 1,
		"experience": 0,
		"total_experience": 0,
		"skill_points": 0,
		"upgrades": {},
		"abilities_unlocked": ["heavy_strike", "berserker_rage"],
		"third_ability_unlocked": false,
		"stats": {
			"max_health": 120,
			"attack_power": 110,
			"move_speed": 85,
			"mana": 60,
			"physical_resistance": 100
		}
	},
	CharacterType.ROGUE: {
		"name": "Rogue",
		"level": 1,
		"experience": 0,
		"total_experience": 0,
		"skill_points": 0,
		"upgrades": {},
		"abilities_unlocked": ["stealth", "poison_strike"],
		"third_ability_unlocked": false,
		"stats": {
			"max_health": 90,
			"attack_power": 100,
			"move_speed": 130,
			"mana": 80,
			"critical_chance": 25
		}
	},
	CharacterType.KNIGHT: {
		"name": "Knight",
		"level": 1,
		"experience": 0,
		"total_experience": 0,
		"skill_points": 0,
		"upgrades": {},
		"abilities_unlocked": ["shield_bash", "protective_aura"],
		"third_ability_unlocked": false,
		"stats": {
			"max_health": 110,
			"attack_power": 85,
			"move_speed": 90,
			"mana": 70,
			"defense": 120
		}
	}
}

# Third abilities for each character
var third_abilities = {
	CharacterType.WIZARD: "meteor_storm",
	CharacterType.BARBARIAN: "earthquake",
	CharacterType.ROGUE: "shadow_clone",
	CharacterType.KNIGHT: "divine_protection"
}

# Upgrade trees for each character
var upgrade_trees = {
	CharacterType.WIZARD: {
		"fire_mastery": {"cost": 2, "max_level": 3, "description": "Increases fire spell damage"},
		"mana_pool": {"cost": 1, "max_level": 5, "description": "Increases maximum mana"},
		"spell_speed": {"cost": 2, "max_level": 3, "description": "Faster spell casting"},
		"elemental_resistance": {"cost": 3, "max_level": 2, "description": "Reduces elemental damage taken"},
		"magic_missile_upgrade": {"cost": 4, "max_level": 1, "description": "Magic missile pierces enemies"}
	},
	CharacterType.BARBARIAN: {
		"strength_training": {"cost": 2, "max_level": 4, "description": "Increases attack power"},
		"tough_skin": {"cost": 1, "max_level": 5, "description": "Increases maximum health"},
		"rage_duration": {"cost": 3, "max_level": 2, "description": "Berserker rage lasts longer"},
		"weapon_mastery": {"cost": 3, "max_level": 3, "description": "Increases critical hit chance"},
		"intimidation": {"cost": 4, "max_level": 1, "description": "Enemies move slower near you"}
	},
	CharacterType.ROGUE: {
		"agility_training": {"cost": 2, "max_level": 4, "description": "Increases movement speed"},
		"poison_mastery": {"cost": 2, "max_level": 3, "description": "Poison does more damage"},
		"stealth_duration": {"cost": 3, "max_level": 2, "description": "Stealth lasts longer"},
		"critical_strikes": {"cost": 1, "max_level": 5, "description": "Increases critical chance"},
		"shadow_step": {"cost": 4, "max_level": 1, "description": "Teleport to target location"}
	},
	CharacterType.KNIGHT: {
		"armor_training": {"cost": 1, "max_level": 5, "description": "Increases defense"},
		"shield_mastery": {"cost": 2, "max_level": 3, "description": "Shield bash does more damage"},
		"healing_aura": {"cost": 3, "max_level": 2, "description": "Protective aura heals allies"},
		"holy_power": {"cost": 3, "max_level": 3, "description": "Increases damage vs undead"},
		"guardian_stance": {"cost": 4, "max_level": 1, "description": "Take damage for nearby allies"}
	}
}

# Global progression stats
var global_stats = {
	"total_runs": 0,
	"successful_runs": 0,
	"total_playtime": 0,
	"enemies_defeated": 0,
	"bosses_defeated": 0,
	"items_collected": 0,
	"deaths": 0,
	"favorite_character": CharacterType.WIZARD
}

# Signals
signal experience_gained(character_type: CharacterType, amount: int)
signal level_up(character_type: CharacterType, new_level: int)
signal skill_point_gained(character_type: CharacterType, points: int)
signal upgrade_purchased(character_type: CharacterType, upgrade_name: String)
signal third_ability_unlocked(character_type: CharacterType, ability_name: String)
signal data_saved()
signal data_loaded()

func _ready():
	print("ProgressionManager initialized")
	load_progression_data()

# Award experience to all characters (shared XP)
func award_experience(amount: int):
	print("Awarding ", amount, " experience to all characters")
	
	for character_type in CharacterType.values():
		var old_level = character_data[character_type]["level"]
		character_data[character_type]["experience"] += amount
		character_data[character_type]["total_experience"] += amount
		
		# Check for level up
		var new_level = calculate_level(character_data[character_type]["experience"])
		if new_level > old_level:
			level_up_character(character_type, new_level)
		
		experience_gained.emit(character_type, amount)
	
	# Update global stats
	global_stats["total_playtime"] += 1  # Simplified tracking
	
	# Auto-save after gaining experience
	save_progression_data()

# Calculate level based on experience
func calculate_level(experience: int) -> int:
	# Experience curve: level = sqrt(experience / 100) + 1
	# Level 1: 0 XP, Level 2: 100 XP, Level 3: 400 XP, etc.
	return int(sqrt(experience / 100.0)) + 1

# Calculate experience needed for next level
func get_experience_for_level(level: int) -> int:
	return (level - 1) * (level - 1) * 100

# Level up character
func level_up_character(character_type: CharacterType, new_level: int):
	var old_level = character_data[character_type]["level"]
	character_data[character_type]["level"] = new_level
	
	# Award skill points
	var skill_points_gained = new_level - old_level
	character_data[character_type]["skill_points"] += skill_points_gained
	
	# Check for third ability unlock
	if new_level >= 5 and not character_data[character_type]["third_ability_unlocked"]:
		unlock_third_ability(character_type)
	
	print("Character ", character_data[character_type]["name"], " leveled up to ", new_level)
	level_up.emit(character_type, new_level)
	skill_point_gained.emit(character_type, skill_points_gained)

# Unlock third ability
func unlock_third_ability(character_type: CharacterType):
	character_data[character_type]["third_ability_unlocked"] = true
	var ability_name = third_abilities[character_type]
	character_data[character_type]["abilities_unlocked"].append(ability_name)
	
	print("Third ability unlocked for ", character_data[character_type]["name"], ": ", ability_name)
	third_ability_unlocked.emit(character_type, ability_name)

# Purchase upgrade
func purchase_upgrade(character_type: CharacterType, upgrade_name: String) -> bool:
	if not upgrade_name in upgrade_trees[character_type]:
		push_error("Invalid upgrade: " + upgrade_name)
		return false
	
	var upgrade_info = upgrade_trees[character_type][upgrade_name]
	var current_level = character_data[character_type]["upgrades"].get(upgrade_name, 0)
	
	# Check if upgrade is at max level
	if current_level >= upgrade_info["max_level"]:
		print("Upgrade ", upgrade_name, " is already at max level")
		return false
	
	# Check if player has enough skill points
	var cost = upgrade_info["cost"]
	if character_data[character_type]["skill_points"] < cost:
		print("Not enough skill points for upgrade: ", upgrade_name)
		return false
	
	# Purchase upgrade
	character_data[character_type]["skill_points"] -= cost
	character_data[character_type]["upgrades"][upgrade_name] = current_level + 1
	
	# Apply upgrade effects
	apply_upgrade_effects(character_type, upgrade_name, current_level + 1)
	
	print("Upgrade purchased: ", upgrade_name, " level ", current_level + 1)
	upgrade_purchased.emit(character_type, upgrade_name)
	
	# Auto-save after purchase
	save_progression_data()
	return true

# Apply upgrade effects to character stats
func apply_upgrade_effects(character_type: CharacterType, upgrade_name: String, level: int):
	var stats = character_data[character_type]["stats"]
	
	match character_type:
		CharacterType.WIZARD:
			match upgrade_name:
				"mana_pool":
					stats["mana"] = 120 + (level * 20)
				"spell_speed":
					# This would affect casting speed (handled in character controller)
					pass
				"elemental_resistance":
					stats["magic_resistance"] = 80 + (level * 10)
		
		CharacterType.BARBARIAN:
			match upgrade_name:
				"strength_training":
					stats["attack_power"] = 110 + (level * 15)
				"tough_skin":
					stats["max_health"] = 120 + (level * 20)
				"weapon_mastery":
					# This would affect critical chance
					pass
		
		CharacterType.ROGUE:
			match upgrade_name:
				"agility_training":
					stats["move_speed"] = 130 + (level * 10)
				"critical_strikes":
					stats["critical_chance"] = 25 + (level * 5)
		
		CharacterType.KNIGHT:
			match upgrade_name:
				"armor_training":
					stats["defense"] = 120 + (level * 15)
				"holy_power":
					# This would affect damage vs undead
					pass

# Get character data
func get_character_data(character_type: CharacterType) -> Dictionary:
	return character_data[character_type].duplicate(true)

# Get all character data
func get_all_character_data() -> Dictionary:
	return character_data.duplicate(true)

# Get upgrade tree for character
func get_upgrade_tree(character_type: CharacterType) -> Dictionary:
	return upgrade_trees[character_type].duplicate(true)

# Get upgrade level
func get_upgrade_level(character_type: CharacterType, upgrade_name: String) -> int:
	return character_data[character_type]["upgrades"].get(upgrade_name, 0)

# Can purchase upgrade
func can_purchase_upgrade(character_type: CharacterType, upgrade_name: String) -> bool:
	if not upgrade_name in upgrade_trees[character_type]:
		return false
	
	var upgrade_info = upgrade_trees[character_type][upgrade_name]
	var current_level = character_data[character_type]["upgrades"].get(upgrade_name, 0)
	var cost = upgrade_info["cost"]
	
	return (current_level < upgrade_info["max_level"] and 
			character_data[character_type]["skill_points"] >= cost)

# Get global stats
func get_global_stats() -> Dictionary:
	return global_stats.duplicate()

# Update global stats
func update_global_stat(stat_name: String, value: int):
	if stat_name in global_stats:
		global_stats[stat_name] += value
		print("Global stat updated: ", stat_name, " = ", global_stats[stat_name])

# Complete run (update global stats)
func complete_run(success: bool, stats: Dictionary):
	global_stats["total_runs"] += 1
	if success:
		global_stats["successful_runs"] += 1
	
	# Update other stats
	global_stats["enemies_defeated"] += stats.get("enemies_killed", 0)
	global_stats["bosses_defeated"] += stats.get("bosses_defeated", 0)
	global_stats["items_collected"] += stats.get("items_collected", 0)
	global_stats["deaths"] += stats.get("deaths", 0)
	
	save_progression_data()

# Save progression data
func save_progression_data():
	var save_data = {
		"character_data": character_data,
		"global_stats": global_stats,
		"version": 1
	}
	
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file:
		var json_string = JSON.stringify(save_data)
		save_file.store_string(json_string)
		save_file.close()
		print("Progression data saved successfully")
		data_saved.emit()
	else:
		push_error("Failed to save progression data")

# Load progression data
func load_progression_data():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No save file found, using default progression data")
		return
	
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if save_file:
		var json_string = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.data
			
			# Load character data
			if "character_data" in save_data:
				character_data = save_data["character_data"]
				
				# Apply all upgrades to recalculate stats
				for character_type in CharacterType.values():
					for upgrade_name in character_data[character_type]["upgrades"]:
						var upgrade_level = character_data[character_type]["upgrades"][upgrade_name]
						apply_upgrade_effects(character_type, upgrade_name, upgrade_level)
			
			# Load global stats
			if "global_stats" in save_data:
				global_stats = save_data["global_stats"]
			
			print("Progression data loaded successfully")
			data_loaded.emit()
		else:
			push_error("Failed to parse save file")
	else:
		push_error("Failed to load progression data")

# Reset all progression (for testing)
func reset_progression():
	# Reset to default values
	_ready()
	
	# Delete save file
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
	
	print("Progression reset")

# Get character by name
func get_character_type_by_name(name: String) -> CharacterType:
	for character_type in CharacterType.values():
		if character_data[character_type]["name"].to_lower() == name.to_lower():
			return character_type
	return CharacterType.WIZARD  # Default

# Get total skill points spent
func get_total_skill_points_spent(character_type: CharacterType) -> int:
	var total = 0
	for upgrade_name in character_data[character_type]["upgrades"]:
		var upgrade_level = character_data[character_type]["upgrades"][upgrade_name]
		var cost = upgrade_trees[character_type][upgrade_name]["cost"]
		total += cost * upgrade_level
	return total

# Get character power level (for balancing)
func get_character_power_level(character_type: CharacterType) -> int:
	var level = character_data[character_type]["level"]
	var upgrade_bonus = get_total_skill_points_spent(character_type)
	return level * 10 + upgrade_bonus 
