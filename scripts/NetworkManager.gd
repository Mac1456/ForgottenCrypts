extends Node

# Network configuration
const PORT = 7000
const MAX_PLAYERS = 4

# Player data structure
var players = {}
var local_player_id = 1

# Network state
var is_host = false
var multiplayer_peer: ENetMultiplayerPeer

# Signals
signal player_connected(id: int)
signal player_disconnected(id: int)
signal connection_failed()
signal connection_succeeded()
signal server_created()

func _ready():
	print("NetworkManager initialized")
	
	# Set up multiplayer
	if multiplayer:
		# Connect multiplayer signals
		if multiplayer.peer_connected.connect(_on_player_connected) == OK:
			print("Connected to multiplayer.peer_connected")
		else:
			push_error("Failed to connect to multiplayer.peer_connected")
		
		if multiplayer.peer_disconnected.connect(_on_player_disconnected) == OK:
			print("Connected to multiplayer.peer_disconnected")
		else:
			push_error("Failed to connect to multiplayer.peer_disconnected")
		
		if multiplayer.connection_failed.connect(_on_connection_failed) == OK:
			print("Connected to multiplayer.connection_failed")
		else:
			push_error("Failed to connect to multiplayer.connection_failed")
		
		if multiplayer.connected_to_server.connect(_on_connection_succeeded) == OK:
			print("Connected to multiplayer.connected_to_server")
		else:
			push_error("Failed to connect to multiplayer.connected_to_server")
		
		if multiplayer.server_disconnected.connect(_on_server_disconnected) == OK:
			print("Connected to multiplayer.server_disconnected")
		else:
			push_error("Failed to connect to multiplayer.server_disconnected")
		
		print("NetworkManager multiplayer signals connected")
	else:
		push_error("Multiplayer not available")
	
	# Set initial local player ID
	local_player_id = 1
	print("Local player ID set to: ", local_player_id)
	
	print("NetworkManager initialization complete")

# Host a game
func host_game() -> bool:
	multiplayer_peer = ENetMultiplayerPeer.new()
	var error = multiplayer_peer.create_server(PORT, MAX_PLAYERS)
	
	if error != OK:
		push_error("Failed to create server: " + str(error))
		return false
	
	multiplayer.multiplayer_peer = multiplayer_peer
	is_host = true
	local_player_id = multiplayer.get_unique_id()
	
	# Add host as first player
	add_player(local_player_id, "Host")
	
	print("Server created successfully on port ", PORT)
	server_created.emit()
	return true

# Join a game
func join_game(address: String) -> bool:
	multiplayer_peer = ENetMultiplayerPeer.new()
	var error = multiplayer_peer.create_client(address, PORT)
	
	if error != OK:
		push_error("Failed to create client: " + str(error))
		return false
	
	multiplayer.multiplayer_peer = multiplayer_peer
	is_host = false
	
	print("Attempting to connect to ", address, ":", PORT)
	return true

# Disconnect from current game
func disconnect_game():
	if multiplayer_peer:
		multiplayer_peer.close()
		multiplayer_peer = null
	
	players.clear()
	is_host = false
	local_player_id = 1
	
	print("Disconnected from game")

# Add player to the network
func add_player(id: int, player_name: String):
	print("Adding player: ", player_name, " (ID: ", id, ")")
	
	if id in players:
		print("Player already exists, updating: ", id)
	
	players[id] = {
		"name": player_name,
		"ready": false,
		"alive": true,
		"health": 100,
		"max_health": 100,
		"character_type": "",
		"score": 0
	}
	
	print("Player added successfully: ", players[id])
	
	# Update local player ID if this is the first player
	if local_player_id == -1:
		local_player_id = id
		print("Local player ID updated to: ", local_player_id)

# Remove player from the network
func remove_player(id: int):
	print("Removing player: ", id)
	
	if id in players:
		var player_name = players[id].get("name", "Unknown")
		players.erase(id)
		print("Player removed successfully: ", player_name, " (ID: ", id, ")")
	else:
		print("Player not found for removal: ", id)

# Get all players
func get_all_players() -> Dictionary:
	print("Getting all players. Count: ", players.size())
	for player_id in players:
		print("Player ", player_id, ": ", players[player_id])
	return players

# Get specific player
func get_player(id: int) -> Dictionary:
	if id in players:
		print("Retrieved player ", id, ": ", players[id])
		return players[id]
	else:
		push_error("Player not found: ", id)
		return {}

# Get player count
func get_player_count() -> int:
	var count = players.size()
	print("Player count: ", count)
	return count

# Check if player is host
func is_player_host(id: int) -> bool:
	return is_host and id == local_player_id

# Update player data (synced across network)
@rpc("any_peer", "call_local", "reliable")
func update_player_data(id: int, data: Dictionary):
	if id in players:
		for key in data:
			players[id][key] = data[key]

# Sync player position (called frequently)
@rpc("any_peer", "call_local", "unreliable")
func sync_player_position(id: int, position: Vector2):
	if id in players:
		players[id]["position"] = position

# Sync player health
@rpc("any_peer", "call_local", "reliable")
func sync_player_health(id: int, health: int, max_health: int):
	if id in players:
		players[id]["health"] = health
		players[id]["max_health"] = max_health

# Player death handling
@rpc("any_peer", "call_local", "reliable")
func player_died(id: int):
	print("Player died: ", id)
	
	if id in players:
		players[id]["alive"] = false
		players[id]["health"] = 0
		print("Player death recorded: ", players[id])
	else:
		push_error("Player not found for death recording: ", id)

# Player revival handling
@rpc("any_peer", "call_local", "reliable")
func revive_player(id: int, health: int = 100):
	print("Reviving player ", id, " with health: ", health)
	
	if id in players:
		players[id]["alive"] = true
		players[id]["health"] = health
		print("Player revived successfully: ", players[id])
	else:
		push_error("Player not found for revival: ", id)

# Set player character
@rpc("any_peer", "call_local", "reliable")
func set_player_character(id: int, character_type: String):
	print("Setting character for player ", id, ": ", character_type)
	
	if id in players:
		players[id]["character_type"] = character_type
		print("Character set successfully: ", players[id])
	else:
		push_error("Player not found for character setting: ", id)

# Set player ready state
@rpc("any_peer", "call_local", "reliable")
func set_player_ready(id: int, ready: bool):
	print("Setting ready state for player ", id, ": ", ready)
	
	if id in players:
		players[id]["ready"] = ready
		print("Ready state set successfully: ", players[id])
	else:
		push_error("Player not found for ready state setting: ", id)

# Check if all players are ready
func all_players_ready() -> bool:
	print("Checking if all players are ready...")
	
	if players.is_empty():
		print("No players found")
		return false
	
	var ready_count = 0
	for player_id in players:
		if not players.has(player_id):
			print("Player ID not found in dictionary: ", player_id)
			continue
			
		var player_data = players[player_id]
		if not player_data:
			print("Player data is null for player ID: ", player_id)
			continue
			
		if player_data.get("ready", false):
			ready_count += 1
		else:
			print("Player ", player_id, " is not ready")
	
	var all_ready = ready_count == players.size()
	print("Ready players: ", ready_count, "/", players.size(), " - All ready: ", all_ready)
	return all_ready

# Network event handlers
func _on_player_connected(id: int):
	print("Player connected: ", id)
	# Request player info from new player
	if is_host:
		rpc_id(id, "request_player_info")
	
	player_connected.emit(id)

func _on_player_disconnected(id: int):
	print("Player disconnected: ", id)
	remove_player(id)
	player_disconnected.emit(id)

func _on_connection_failed():
	print("Connection failed")
	connection_failed.emit()

func _on_connection_succeeded():
	print("Connection succeeded")
	local_player_id = multiplayer.get_unique_id()
	connection_succeeded.emit()

func _on_server_disconnected():
	print("Server disconnected")
	disconnect_game()

# Request player info from joining player
@rpc("any_peer", "call_local", "reliable")
func request_player_info():
	# Send player info to host
	rpc_id(1, "receive_player_info", local_player_id, "Player" + str(local_player_id))

# Receive player info from joining player
@rpc("any_peer", "call_local", "reliable")
func receive_player_info(id: int, player_name: String):
	if is_host:
		add_player(id, player_name)
		# Send current player list to new player
		rpc_id(id, "sync_player_list", players)

# Sync player list for new players
@rpc("any_peer", "call_local", "reliable")
func sync_player_list(player_list: Dictionary):
	players = player_list
	print("Player list synced: ", players.keys())

# Start game (host only)
@rpc("any_peer", "call_local", "reliable")
func start_game():
	if is_host:
		print("Starting game...")
		# Load game scene
		get_tree().change_scene_to_file("res://scenes/GameWorld.tscn")

# Get difficulty scaling based on player count
func get_difficulty_multiplier() -> float:
	var player_count = get_player_count()
	match player_count:
		1:
			return 1.0
		2:
			return 1.3
		3:
			return 1.6
		4:
			return 2.0
		_:
			return 1.0

# Get boss health scaling
func get_boss_health_multiplier() -> float:
	var player_count = get_player_count()
	match player_count:
		1:
			return 1.0
		2:
			return 1.5
		3:
			return 2.0
		4:
			return 2.5
		_:
			return 1.0

# Get enemy spawn rate multiplier
func get_spawn_rate_multiplier() -> float:
	var player_count = get_player_count()
	match player_count:
		1:
			return 1.0
		2:
			return 1.4
		3:
			return 1.8
		4:
			return 2.2
		_:
			return 1.0 
