extends Control

# UI nodes
@onready var main_buttons = $VBoxContainer/MenuButtons
@onready var network_status = $VBoxContainer/NetworkStatus
@onready var join_dialog = $JoinGameDialog
@onready var ip_input = $JoinGameDialog/VBoxContainer/IPInput
@onready var connect_button = $JoinGameDialog/VBoxContainer/ConnectButton
@onready var status_label = $JoinGameDialog/VBoxContainer/StatusLabel
@onready var lobby_panel = $LobbyPanel
@onready var player_list = $LobbyPanel/VBoxContainer/PlayerList
@onready var ready_button = $LobbyPanel/VBoxContainer/LobbyButtons/ReadyButton
@onready var start_game_button = $LobbyPanel/VBoxContainer/LobbyButtons/StartGameButton
@onready var character_select_button = $LobbyPanel/VBoxContainer/LobbyButtons/CharacterSelectButton

# State variables
var is_ready = false
var selected_character = ""

func _ready():
	print("MainMenu loaded")
	
	# Set game state
	GameManager.set_game_state(GameManager.GameState.MENU)
	
	# Validate critical autoload nodes
	if not _validate_autoload_nodes():
		push_error("Critical autoload nodes missing - game cannot function properly")
		return
	
	# Connect to NetworkManager signals
	if not _connect_network_signals():
		push_error("Failed to connect NetworkManager signals")
		return
	
	# Connect to GameManager signals
	if not _connect_game_manager_signals():
		push_error("Failed to connect GameManager signals")
		return
	
	# Update network status
	update_network_status()
	
	# Set default IP input
	if ip_input:
		ip_input.text = "127.0.0.1"
	else:
		push_error("IP input node not found")
	
	# Hide lobby initially
	if lobby_panel:
		lobby_panel.visible = false
	else:
		push_error("Lobby panel node not found")
	
	# Update lobby display
	update_lobby_display()
	
	print("MainMenu initialization complete")

func _validate_autoload_nodes() -> bool:
	var validation_passed = true
	
	if not GameManager:
		push_error("GameManager autoload not found")
		validation_passed = false
	
	if not NetworkManager:
		push_error("NetworkManager autoload not found")
		validation_passed = false
	
	if not ProgressionManager:
		push_error("ProgressionManager autoload not found")
		validation_passed = false
	
	if not AudioManager:
		push_error("AudioManager autoload not found")
		validation_passed = false
	
	print("Autoload validation: ", "PASSED" if validation_passed else "FAILED")
	return validation_passed

func _connect_network_signals() -> bool:
	var connections_made = 0
	var expected_connections = 5
	
	if NetworkManager.server_created.connect(_on_server_created) == OK:
		connections_made += 1
	else:
		push_error("Failed to connect server_created signal")
	
	if NetworkManager.connection_succeeded.connect(_on_connection_succeeded) == OK:
		connections_made += 1
	else:
		push_error("Failed to connect connection_succeeded signal")
	
	if NetworkManager.connection_failed.connect(_on_connection_failed) == OK:
		connections_made += 1
	else:
		push_error("Failed to connect connection_failed signal")
	
	if NetworkManager.player_connected.connect(_on_player_connected) == OK:
		connections_made += 1
	else:
		push_error("Failed to connect player_connected signal")
	
	if NetworkManager.player_disconnected.connect(_on_player_disconnected) == OK:
		connections_made += 1
	else:
		push_error("Failed to connect player_disconnected signal")
	
	print("NetworkManager signal connections: ", connections_made, "/", expected_connections)
	return connections_made == expected_connections

func _connect_game_manager_signals() -> bool:
	if GameManager.game_state_changed.connect(_on_game_state_changed) == OK:
		print("GameManager signal connection: SUCCESS")
		return true
	else:
		push_error("Failed to connect game_state_changed signal")
		return false

func _on_host_game_button_pressed():
	print("Host game button pressed")
	
	# Disable buttons during connection
	set_buttons_enabled(false)
	
	if NetworkManager.host_game():
		network_status.text = "Hosting game..."
		print("Successfully started hosting")
	else:
		network_status.text = "Failed to host game"
		set_buttons_enabled(true)

func _on_join_game_button_pressed():
	print("Join game button pressed")
	join_dialog.popup_centered()

func _on_single_player_button_pressed():
	print("Single player button pressed")
	
	# Set up single player mode
	NetworkManager.add_player(1, "Player")
	
	# Show character selection
	show_character_selection()

func _on_progression_button_pressed():
	print("Progression button pressed")
	# TODO: Load progression/upgrade scene
	pass

func _on_quit_button_pressed():
	print("Quit button pressed")
	get_tree().quit()

func _on_connect_button_pressed():
	var ip_address = ip_input.text.strip_edges()
	if ip_address.is_empty():
		ip_address = "127.0.0.1"
	
	print("Attempting to connect to: ", ip_address)
	status_label.text = "Connecting..."
	connect_button.disabled = true
	
	if NetworkManager.join_game(ip_address):
		print("Connection attempt started")
	else:
		status_label.text = "Failed to start connection"
		connect_button.disabled = false

func _on_character_select_button_pressed():
	print("Character select button pressed")
	show_character_selection()

func _on_ready_button_pressed():
	print("Ready button pressed")
	is_ready = !is_ready
	
	# Update ready state
	NetworkManager.set_player_ready(NetworkManager.local_player_id, is_ready)
	
	# Update UI
	update_ready_button()
	update_lobby_display()

func _on_start_game_button_pressed():
	print("Start game button pressed")
	
	if NetworkManager.is_host and NetworkManager.all_players_ready():
		# Start the game
		GameManager.set_game_state(GameManager.GameState.CHARACTER_SELECT)
		NetworkManager.start_game()
	else:
		print("Cannot start game - not all players ready or not host")

func _on_leave_lobby_button_pressed():
	print("Leave lobby button pressed")
	
	# Disconnect from network
	NetworkManager.disconnect_game()
	
	# Hide lobby
	lobby_panel.visible = false
	
	# Show main menu
	main_buttons.visible = true
	
	# Reset state
	is_ready = false
	selected_character = ""
	
	# Update UI
	update_network_status()
	set_buttons_enabled(true)

# Network event handlers
func _on_server_created():
	print("Server created successfully")
	network_status.text = "Hosting on port " + str(NetworkManager.PORT)
	
	# Show lobby
	show_lobby()

func _on_connection_succeeded():
	print("Connected to server")
	join_dialog.hide()
	network_status.text = "Connected to server"
	
	# Show lobby
	show_lobby()

func _on_connection_failed():
	print("Connection failed")
	status_label.text = "Connection failed"
	connect_button.disabled = false
	set_buttons_enabled(true)

func _on_player_connected(id: int):
	print("Player connected: ", id)
	update_lobby_display()

func _on_player_disconnected(id: int):
	print("Player disconnected: ", id)
	update_lobby_display()

func _on_game_state_changed(new_state: GameManager.GameState):
	print("Game state changed to: ", GameManager.GameState.find_key(new_state))

# UI helper functions
func show_lobby():
	main_buttons.visible = false
	lobby_panel.visible = true
	update_lobby_display()
	
	# Only host can start game
	start_game_button.visible = NetworkManager.is_host

func update_lobby_display():
	if not lobby_panel.visible:
		return
	
	# Clear current player list
	for child in player_list.get_children():
		child.queue_free()
	
	# Add players to list
	var players = NetworkManager.get_all_players()
	if players.is_empty():
		print("No players found for lobby display")
		return
	
	for player_id in players:
		if not players.has(player_id):
			print("Player ID not found in players dictionary: ", player_id)
			continue
			
		var player_data = players[player_id]
		if not player_data:
			print("Player data is null for player ID: ", player_id)
			continue
			
		var player_label = Label.new()
		
		var status_text = ""
		if player_data.get("ready", false):
			status_text = " [READY]"
		
		var character_text = ""
		if not player_data.get("character_type", "").is_empty():
			character_text = " (" + player_data["character_type"] + ")"
		
		var player_name = player_data.get("name", "Unknown Player")
		player_label.text = player_name + character_text + status_text
		player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		player_list.add_child(player_label)
	
	# Update start game button
	if NetworkManager.is_host:
		start_game_button.disabled = not NetworkManager.all_players_ready()

func update_ready_button():
	if is_ready:
		ready_button.text = "Not Ready"
		ready_button.modulate = Color.RED
	else:
		ready_button.text = "Ready"
		ready_button.modulate = Color.WHITE

func update_network_status():
	if NetworkManager.is_host:
		network_status.text = "Hosting on port " + str(NetworkManager.PORT)
	elif NetworkManager.multiplayer_peer != null:
		network_status.text = "Connected to server"
	else:
		network_status.text = "Not Connected"

func set_buttons_enabled(enabled: bool):
	for button in main_buttons.get_children():
		button.disabled = not enabled

func show_character_selection():
	print("Loading character selection...")
	
	# Validate character options
	var character_options = ["Wizard", "Barbarian", "Rogue", "Knight"]
	print("Available character options: ", character_options)
	
	# Create a simple option dialog
	var option_dialog = AcceptDialog.new()
	option_dialog.title = "Select Character"
	option_dialog.size = Vector2i(300, 400)
	
	var vbox = VBoxContainer.new()
	if not vbox:
		push_error("Failed to create VBoxContainer for character selection")
		return
	
	option_dialog.add_child(vbox)
	
	var label = Label.new()
	if not label:
		push_error("Failed to create Label for character selection")
		return
	
	label.text = "Choose your character:"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	# Add character buttons
	var buttons_created = 0
	for character in character_options:
		var button = Button.new()
		if not button:
			push_error("Failed to create Button for character: ", character)
			continue
		
		button.text = character
		button.custom_minimum_size = Vector2(200, 40)
		
		# Connect button signal
		if button.pressed.connect(_on_character_selected.bind(character, option_dialog)) == OK:
			buttons_created += 1
			print("Created button for character: ", character)
		else:
			push_error("Failed to connect button signal for character: ", character)
		
		vbox.add_child(button)
	
	print("Character selection buttons created: ", buttons_created, "/", character_options.size())
	
	add_child(option_dialog)
	option_dialog.popup_centered()
	
	print("Character selection dialog displayed")

func _on_character_selected(character: String, dialog: AcceptDialog):
	print("Selected character: ", character)
	selected_character = character
	
	# Validate character selection
	if not _validate_character_selection(character):
		push_error("Invalid character selection: ", character)
		return
	
	# Update network
	if NetworkManager:
		NetworkManager.set_player_character(NetworkManager.local_player_id, character)
		print("Character updated in NetworkManager: ", character)
	else:
		push_error("NetworkManager not available for character update")
		return
	
	# Update UI
	update_lobby_display()
	
	# Close dialog
	if dialog:
		dialog.queue_free()
		print("Character selection dialog closed")
	else:
		push_error("Character selection dialog reference is null")
	
	# For single player, start game immediately
	if NetworkManager.get_player_count() == 1:
		print("Single player mode detected, starting game...")
		start_single_player_game()
	else:
		print("Multiplayer mode, waiting for other players...")

func _validate_character_selection(character: String) -> bool:
	var valid_characters = ["Wizard", "Barbarian", "Rogue", "Knight"]
	var is_valid = character in valid_characters
	
	if not is_valid:
		push_error("Invalid character selection: ", character, ". Valid options: ", valid_characters)
	
	return is_valid

func start_single_player_game():
	print("Starting single player game...")
	
	# Validate prerequisites
	if not _validate_single_player_prerequisites():
		push_error("Prerequisites not met for single player game")
		return
	
	# Set player as ready
	is_ready = true
	if NetworkManager:
		NetworkManager.set_player_ready(NetworkManager.local_player_id, true)
		print("Player set as ready")
	else:
		push_error("NetworkManager not available")
		return
	
	# Start game
	if GameManager:
		GameManager.start_new_run()
		print("New run started via GameManager")
	else:
		push_error("GameManager not available")
		return
	
	# Add a small delay to ensure everything is initialized
	await get_tree().create_timer(0.1).timeout
	
	# Validate scene path before loading
	var scene_path = "res://scenes/GameWorld.tscn"
	if not ResourceLoader.exists(scene_path):
		push_error("GameWorld scene not found at: ", scene_path)
		return
	
	print("Loading game world from: ", scene_path)
	
	# Preload the scene first to catch any loading errors
	var game_world_scene = load(scene_path)
	if not game_world_scene:
		push_error("Failed to load GameWorld scene resource")
		return
	print("GameWorld scene loaded successfully")
	
	# Change scene with error handling
	var result = get_tree().change_scene_to_file(scene_path)
	
	if result == OK:
		print("Successfully initiated GameWorld scene loading")
	else:
		push_error("Failed to load GameWorld scene. Error code: ", result)
		# Try to recover by going back to a safe state
		GameManager.set_game_state(GameManager.GameState.MENU)
		print("Recovered to menu state due to scene loading failure")

func _validate_single_player_prerequisites() -> bool:
	var validation_passed = true
	
	if not NetworkManager:
		push_error("NetworkManager required for single player game")
		validation_passed = false
	
	if not GameManager:
		push_error("GameManager required for single player game")
		validation_passed = false
	
	if selected_character.is_empty():
		push_error("No character selected")
		validation_passed = false
	
	if NetworkManager and NetworkManager.get_player_count() == 0:
		push_error("No players in NetworkManager")
		validation_passed = false
	
	print("Single player prerequisites: ", "PASSED" if validation_passed else "FAILED")
	return validation_passed

func _input(event):
	# Handle escape key to close dialogs
	if event.is_action_pressed("ui_cancel"):
		if join_dialog and join_dialog.visible:
			join_dialog.hide()
		elif lobby_panel and lobby_panel.visible:
			_on_leave_lobby_button_pressed()
	
	# Debug shortcuts
	if OS.is_debug_build():
		if event.is_action_pressed("ui_accept"):
			# Run diagnostic test
			print("Running diagnostic test...")
			run_diagnostic_test()
		elif event.is_action_pressed("ui_select"):
			# Run comprehensive debug check
			print("Running comprehensive debug check...")
			run_comprehensive_debug_check()

func run_diagnostic_test():
	print("\n=== DIAGNOSTIC TEST: Character Selection -> GameWorld Loading ===")
	
	# Test 1: Validate basic autoload nodes
	print("\n1. Validating autoload nodes...")
	if not _validate_autoload_nodes():
		print("DIAGNOSTIC FAILED: Autoload nodes missing")
		return
	
	# Test 2: Simulate character selection FIRST
	print("\n2. Simulating character selection...")
	if not NetworkManager:
		print("DIAGNOSTIC FAILED: NetworkManager not available")
		return
	
	# Add test player
	print("Adding test player...")
	NetworkManager.add_player(1, "DiagnosticPlayer")
	
	# Set character selection
	print("Setting character selection...")
	NetworkManager.set_player_character(1, "Wizard")
	selected_character = "Wizard"  # Set the MainMenu variable too
	
	# Set ready state
	print("Setting ready state...")
	NetworkManager.set_player_ready(1, true)
	
	# Validate player data
	var player_data = NetworkManager.get_player(1)
	if player_data.get("character_type") != "Wizard":
		print("DIAGNOSTIC FAILED: Character not set correctly")
		return
	
	print("Character selection simulated successfully")
	
	# Test 3: NOW validate prerequisites (after player is added)
	print("\n3. Validating prerequisites...")
	if not _validate_single_player_prerequisites():
		print("DIAGNOSTIC FAILED: Single player prerequisites not met")
		return
	
	# Test 4: Test GameManager
	print("\n4. Testing GameManager...")
	if not GameManager:
		print("DIAGNOSTIC FAILED: GameManager not available")
		return
	
	var level_info = GameManager.get_current_level_info()
	if level_info.is_empty():
		print("DIAGNOSTIC FAILED: Level info is empty")
		return
	
	print("GameManager level info: ", level_info)
	
	# Test 5: Test scene loading
	print("\n5. Testing scene loading...")
	var scene_path = "res://scenes/GameWorld.tscn"
	if not ResourceLoader.exists(scene_path):
		print("DIAGNOSTIC FAILED: GameWorld scene not found")
		return
	
	var scene = load(scene_path)
	if not scene:
		print("DIAGNOSTIC FAILED: GameWorld scene failed to load")
		return
	
	print("GameWorld scene loaded successfully")
	
	# Test 6: Test character scripts
	print("\n6. Testing character scripts...")
	var character_scripts = [
		"res://scripts/characters/Wizard.gd",
		"res://scripts/characters/Barbarian.gd",
		"res://scripts/characters/Rogue.gd",
		"res://scripts/characters/Knight.gd"
	]
	
	for script_path in character_scripts:
		if not ResourceLoader.exists(script_path):
			print("DIAGNOSTIC FAILED: Character script not found: ", script_path)
			return
		
		var script = load(script_path)
		if not script:
			print("DIAGNOSTIC FAILED: Character script failed to load: ", script_path)
			return
	
	print("All character scripts loaded successfully")
	
	# Test 7: Test GameLevel scene
	print("\n7. Testing GameLevel scene...")
	var level_scene_path = "res://scenes/levels/GameLevel.tscn"
	if not ResourceLoader.exists(level_scene_path):
		print("DIAGNOSTIC FAILED: GameLevel scene not found")
		return
	
	var level_scene = load(level_scene_path)
	if not level_scene:
		print("DIAGNOSTIC FAILED: GameLevel scene failed to load")
		return
	
	print("GameLevel scene loaded successfully")
	
	# Test 8: Test game start process
	print("\n8. Testing game start process...")
	GameManager.start_new_run()
	print("Game start process completed successfully")
	
	# Clean up
	print("\n9. Cleaning up test environment...")
	NetworkManager.remove_player(1)
	selected_character = ""  # Reset selected character
	print("Test environment cleaned up")
	
	print("\n=== DIAGNOSTIC TEST COMPLETED SUCCESSFULLY ===")
	print("All systems appear to be working correctly.")
	print("If the game still doesn't load, the issue may be in the GameWorld scene instantiation.")
	print("Try running the game normally and check the console output for detailed error messages.")

# Debug function to test progression system
func _on_debug_add_xp_pressed():
	if ProgressionManager:
		ProgressionManager.award_experience(100)
		print("Added 100 XP to all characters")
	else:
		print("ProgressionManager not available")

func _on_debug_reset_progression_pressed():
	if ProgressionManager:
		ProgressionManager.reset_progression()
		print("Reset all progression")
	else:
		print("ProgressionManager not available")

func run_comprehensive_debug_check():
	print("\\n=== COMPREHENSIVE DEBUG CHECK ===")
	
	# Load and run the debug script
	var debug_script = load("res://debug_game_loading.gd")
	if debug_script:
		var debug_instance = debug_script.new()
		add_child(debug_instance)
		debug_instance.run_comprehensive_debug()
		debug_instance.queue_free()
	else:
		print("Could not load debug script")
