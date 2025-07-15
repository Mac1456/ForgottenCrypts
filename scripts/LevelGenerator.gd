extends Node

# Level types for different themes
enum LevelType {
	CAVE,
	CATACOMB,
	CRYPT,
	CASTLE
}

# Room generation parameters
const MIN_ROOM_SIZE = 8
const MAX_ROOM_SIZE = 16
const MIN_ROOMS = 4
const MAX_ROOMS = 8
const CORRIDOR_WIDTH = 3
const TILE_SIZE = 16

# Tile IDs for different tile types
const WALL_TILE = 0
const FLOOR_TILE = 1
const DOOR_TILE = 2
const SPAWN_TILE = 3
const BOSS_TILE = 4

# Room data structure
class Room:
	var x: int
	var y: int
	var width: int
	var height: int
	var center: Vector2
	var is_boss_room: bool = false
	var is_spawn_room: bool = false
	var connected_rooms: Array = []
	
	func _init(x_pos: int, y_pos: int, w: int, h: int):
		x = x_pos
		y = y_pos
		width = w
		height = h
		center = Vector2(x + width / 2.0, y + height / 2.0)
	
	func overlaps(other_room: Room) -> bool:
		return not (x + width < other_room.x or other_room.x + other_room.width < x or 
				   y + height < other_room.y or other_room.y + other_room.height < y)
	
	func get_bounds() -> Rect2:
		return Rect2(x, y, width, height)

# Level data
var level_width: int = 40
var level_height: int = 30
var level_data: Array = []
var rooms: Array = []
var corridors: Array = []
var spawn_points: Array = []
var enemy_spawn_points: Array = []
var boss_spawn_point: Vector2

# Signals
signal level_generated(tilemap: TileMap)
signal spawn_points_ready(player_spawns: Array, enemy_spawns: Array, boss_spawn: Vector2)

func _ready():
	print("LevelGenerator initialized")

# Generate a complete level
func generate_level(level_type: LevelType, seed_value: int = -1) -> TileMap:
	print("Generating level of type: ", LevelType.keys()[level_type])
	
	# Set random seed for reproducible levels
	if seed_value != -1:
		seed(seed_value)
	else:
		randomize()
	
	# Always use fallback level for now to avoid texture issues
	print("Using fallback level generation to avoid texture loading issues...")
	var tilemap = await _create_emergency_fallback_level(level_type)
	
	# Emit signals
	level_generated.emit(tilemap)
	spawn_points_ready.emit(spawn_points, enemy_spawn_points, boss_spawn_point)
	
	return tilemap

# Create emergency fallback level with minimal processing
func _create_emergency_fallback_level(level_type: LevelType) -> TileMap:
	print("Creating emergency fallback level...")
	
	# Create a very simple rectangular room
	var fallback_width = 15
	var fallback_height = 10
	
	# Clear and resize level data
	level_data.clear()
	rooms.clear()
	corridors.clear()
	spawn_points.clear()
	enemy_spawn_points.clear()
	
	level_width = fallback_width
	level_height = fallback_height
	
	# Initialize with walls
	for x in range(level_width):
		level_data.append([])
		for y in range(level_height):
			level_data[x].append(WALL_TILE)
	
	# Create a single room in the center
	var room_x = 1
	var room_y = 1
	var room_width = fallback_width - 2
	var room_height = fallback_height - 2
	
	var fallback_room = Room.new(room_x, room_y, room_width, room_height)
	rooms.append(fallback_room)
	
	# Carve out the room
	for x in range(room_x, room_x + room_width):
		for y in range(room_y, room_y + room_height):
			level_data[x][y] = FLOOR_TILE
	
	# Create spawn points
	spawn_points.append(Vector2(room_x + 2, room_y + 2) * TILE_SIZE)
	enemy_spawn_points.append(Vector2(room_x + room_width - 3, room_y + room_height - 3) * TILE_SIZE)
	boss_spawn_point = Vector2(room_x + room_width / 2, room_y + room_height / 2) * TILE_SIZE
	
	print("Emergency fallback level created: ", fallback_width, "x", fallback_height, " with 1 room")
	
	# Create tilemap with emergency settings
	var tilemap = await _create_emergency_tilemap(level_type)
	return tilemap

# Create emergency tilemap with procedural texture
func _create_emergency_tilemap(level_type: LevelType) -> TileMap:
	print("Creating emergency tilemap...")
	
	var tilemap = TileMap.new()
	var tileset = _create_emergency_tileset(level_type)
	tilemap.tile_set = tileset
	
	var total_tiles = level_width * level_height
	var tiles_processed = 0
	
	print("Processing ", total_tiles, " tiles for emergency level...")
	
	# Process in ultra-small batches with maximum yielding
	var batch_size = 10  # Ultra-small batch size
	var current_batch = 0
	
	for x in range(level_width):
		for y in range(level_height):
			var tile_id = level_data[x][y]
			var atlas_coords = Vector2i(0, 0) if tile_id == WALL_TILE else Vector2i(0, 1)
			
			tilemap.set_cell(0, Vector2i(x, y), 0, atlas_coords)
			tiles_processed += 1
			current_batch += 1
			
			# Yield very frequently for emergency level
			if current_batch >= batch_size:
				current_batch = 0
				await Engine.get_main_loop().process_frame
				
				# Progress logging every 50 tiles
				if tiles_processed % 50 == 0:
					print("Emergency tiles processed: ", tiles_processed, "/", total_tiles)
	
	print("Emergency tilemap creation complete - ", tiles_processed, " tiles processed")
	return tilemap

# Create emergency tileset with procedural texture
func _create_emergency_tileset(level_type: LevelType) -> TileSet:
	print("Creating emergency tileset with procedural texture...")
	
	var tileset = TileSet.new()
	
	# Set up physics layers in tileset FIRST (required for collision)
	tileset.add_physics_layer(0)
	print("Added physics layer 0 to emergency tileset")
	
	var source = TileSetAtlasSource.new()
	
	# Create a simple procedural texture
	var texture_size = 32
	var image = Image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)
	
	# Fill with simple pattern
	for x in range(texture_size):
		for y in range(texture_size):
			if x < 16 and y < 16:
				# Wall tile (top-left) - dark gray
				image.set_pixel(x, y, Color(0.3, 0.3, 0.3, 1.0))
			elif x >= 16 and y < 16:
				# Unused (top-right) - black
				image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 1.0))
			elif x < 16 and y >= 16:
				# Floor tile (bottom-left) - light gray
				image.set_pixel(x, y, Color(0.7, 0.7, 0.7, 1.0))
			else:
				# Unused (bottom-right) - black
				image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 1.0))
	
	# Create texture from image
	var texture = ImageTexture.create_from_image(image)
	source.texture = texture
	
	# Configure tile size
	source.texture_region_size = Vector2i(16, 16)
	
	# Add source to tileset BEFORE configuring tiles
	tileset.add_source(source, 0)
	
	# Add basic tiles with minimal configuration
	_configure_emergency_tiles(source, tileset)
	
	print("Emergency tileset created successfully")
	return tileset

# Configure minimal tiles for emergency tileset
func _configure_emergency_tiles(source: TileSetAtlasSource, tileset: TileSet):
	if not source:
		push_error("TileSetAtlasSource is null")
		return
	
	# Add only the essential tiles
	var wall_coords = Vector2i(0, 0)
	var floor_coords = Vector2i(0, 1)
	
	# Create wall tile
	source.create_tile(wall_coords)
	var wall_tile_data = source.get_tile_data(wall_coords, 0)
	if wall_tile_data:
		# Skip collision setup for now to avoid API issues
		print("Wall tile created at ", wall_coords)
	
	# Create floor tile (no collision)
	source.create_tile(floor_coords)
	var floor_tile_data = source.get_tile_data(floor_coords, 0)
	if floor_tile_data:
		# Floor tiles don't need collision - just create the tile
		print("Floor tile created at ", floor_coords)
	
	print("Emergency tiles configured: wall and floor tiles only")

# Initialize level data array
func _initialize_level_data():
	level_data.clear()
	rooms.clear()
	corridors.clear()
	spawn_points.clear()
	enemy_spawn_points.clear()
	
	# Fill with walls
	for x in range(level_width):
		level_data.append([])
		for y in range(level_height):
			level_data[x].append(WALL_TILE)

# Generate rooms using BSP or random placement
func _generate_rooms():
	var num_rooms = randi_range(MIN_ROOMS, MAX_ROOMS)
	var attempts = 0
	var max_attempts = 50  # Reduced from 100 to prevent long loops
	
	print("Attempting to generate ", num_rooms, " rooms...")
	
	while rooms.size() < num_rooms and attempts < max_attempts:
		attempts += 1
		
		# Generate random room
		var room_width = randi_range(MIN_ROOM_SIZE, MAX_ROOM_SIZE)
		var room_height = randi_range(MIN_ROOM_SIZE, MAX_ROOM_SIZE)
		var room_x = randi_range(2, level_width - room_width - 2)
		var room_y = randi_range(2, level_height - room_height - 2)
		
		var new_room = Room.new(room_x, room_y, room_width, room_height)
		
		# Check if room overlaps with existing rooms
		var overlaps = false
		for existing_room in rooms:
			if new_room.overlaps(existing_room):
				overlaps = true
				break
		
		if not overlaps:
			rooms.append(new_room)
			_carve_room(new_room)
	
	# Designate special rooms
	if rooms.size() > 0:
		# First room is spawn room
		rooms[0].is_spawn_room = true
		
		# Last room is boss room
		if rooms.size() > 1:
			rooms[rooms.size() - 1].is_boss_room = true
	
	print("Generated ", rooms.size(), " rooms")

# Carve out a room in the level data
func _carve_room(room: Room):
	for x in range(room.x, room.x + room.width):
		for y in range(room.y, room.y + room.height):
			if x < level_width and y < level_height:
				level_data[x][y] = FLOOR_TILE

# Connect rooms with corridors
func _connect_rooms():
	if rooms.size() < 2:
		return
	
	# Connect each room to the next one
	for i in range(rooms.size() - 1):
		var room_a = rooms[i]
		var room_b = rooms[i + 1]
		
		_create_corridor(room_a.center, room_b.center)
		room_a.connected_rooms.append(room_b)
		room_b.connected_rooms.append(room_a)
	
	# Add some additional connections for complexity
	var extra_connections = randi_range(2, 4)
	for i in range(extra_connections):
		var room_a = rooms[randi() % rooms.size()]
		var room_b = rooms[randi() % rooms.size()]
		
		if room_a != room_b and not room_a.connected_rooms.has(room_b):
			_create_corridor(room_a.center, room_b.center)
			room_a.connected_rooms.append(room_b)
			room_b.connected_rooms.append(room_a)

# Create a corridor between two points
func _create_corridor(start: Vector2, end: Vector2):
	var current = start
	var target = end
	
	# Create L-shaped corridor
	while current != target:
		# Move horizontally first
		if current.x < target.x:
			current.x += 1
		elif current.x > target.x:
			current.x -= 1
		# Then move vertically
		elif current.y < target.y:
			current.y += 1
		elif current.y > target.y:
			current.y -= 1
		
		# Carve corridor
		_carve_corridor_tile(current)

# Carve a corridor tile (with some width)
func _carve_corridor_tile(pos: Vector2):
	var width = CORRIDOR_WIDTH
	var half_width = width / 2
	
	for x in range(pos.x - half_width, pos.x + half_width + 1):
		for y in range(pos.y - half_width, pos.y + half_width + 1):
			if x >= 0 and x < level_width and y >= 0 and y < level_height:
				level_data[x][y] = FLOOR_TILE

# Create spawn points
func _create_spawn_points():
	# Player spawn points in spawn room
	for room in rooms:
		if room.is_spawn_room:
			for i in range(4):  # Support up to 4 players
				var spawn_x = room.x + 2 + (i % 2) * 2
				var spawn_y = room.y + 2 + (i / 2) * 2
				spawn_points.append(Vector2(spawn_x * TILE_SIZE, spawn_y * TILE_SIZE))
		
		elif room.is_boss_room:
			# Boss spawn point
			boss_spawn_point = Vector2(room.center.x * TILE_SIZE, room.center.y * TILE_SIZE)
		
		else:
			# Enemy spawn points in other rooms
			var num_spawns = randi_range(1, 3)
			for i in range(num_spawns):
				var spawn_x = room.x + randi_range(2, room.width - 2)
				var spawn_y = room.y + randi_range(2, room.height - 2)
				enemy_spawn_points.append(Vector2(spawn_x * TILE_SIZE, spawn_y * TILE_SIZE))

# Create TileSet resource based on level type
func _create_tileset(level_type: LevelType) -> TileSet:
	var tileset = TileSet.new()
	
	# Create TileSetAtlasSource
	var source = TileSetAtlasSource.new()
	
	# Set texture based on level type with error handling
	var texture_path = ""
	match level_type:
		LevelType.CAVE:
			texture_path = "res://assets/environments/rpgw_caves/MainLev2.0.png"
		LevelType.CATACOMB:
			texture_path = "res://assets/environments/kenney_dungeons/Spritesheet/roguelikeDungeon_transparent.png"
		LevelType.CRYPT:
			texture_path = "res://assets/tilesets/mainlev_build.png"
		LevelType.CASTLE:
			texture_path = "res://assets/characters/32rogues/32rogues/tiles.png"
	
	# Load texture with error handling
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path)
		if texture:
			source.texture = texture
		else:
			print("Using placeholder texture")
			source.texture = load("res://assets/placeholders/gray_texture.png")
	else:
		push_error("Texture file does not exist: ", texture_path)
		# Use a fallback texture
		var fallback_image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		fallback_image.fill(Color.GRAY)
		var fallback_texture = ImageTexture.create_from_image(fallback_image)
		source.texture = fallback_texture
	
	# Configure tile size
	source.texture_region_size = Vector2i(16, 16)
	
	# Set up physics layers in tileset (required for collision)
	tileset.add_physics_layer(0)
	print("Added physics layer 0 to tileset")
	
	# Add basic tiles
	_configure_tileset_tiles(source, level_type)
	
	# Add source to tileset
	tileset.add_source(source, 0)
	
	return tileset

# Configure tiles in the tileset
func _configure_tileset_tiles(source: TileSetAtlasSource, _level_type: LevelType):
	if not source:
		push_error("TileSetAtlasSource is null")
		return
	
	# Add wall tiles
	for x in range(4):
		for y in range(4):
			var tile_coords = Vector2i(x, y)
			
			# Create tile with error handling
			source.create_tile(tile_coords)
			var tile_data = source.get_tile_data(tile_coords, 0)
			
			if tile_data:
				# Set collision for wall tiles
				if x < 2 or y < 2:  # Wall tiles
					# Create collision polygon for wall tiles
					tile_data.set_collision_polygons_count(0, 1)
					var collision_polygon = PackedVector2Array([Vector2(0, 0), Vector2(16, 0), Vector2(16, 16), Vector2(0, 16)])
					tile_data.set_collision_polygon(0, 0, collision_polygon)
			else:
				push_error("Failed to get tile data for tile: ", tile_coords)

# Get tile coordinates for different tile types
func _get_wall_tile_coords(level_type: LevelType) -> Vector2i:
	match level_type:
		LevelType.CAVE:
			return Vector2i(0, 0)  # Cave wall
		LevelType.CATACOMB:
			return Vector2i(1, 0)  # Stone wall
		LevelType.CRYPT:
			return Vector2i(2, 0)  # Crypt wall
		LevelType.CASTLE:
			return Vector2i(3, 0)  # Castle wall
		_:
			return Vector2i(0, 0)

func _get_floor_tile_coords(level_type: LevelType) -> Vector2i:
	match level_type:
		LevelType.CAVE:
			return Vector2i(0, 1)  # Cave floor
		LevelType.CATACOMB:
			return Vector2i(1, 1)  # Stone floor
		LevelType.CRYPT:
			return Vector2i(2, 1)  # Crypt floor
		LevelType.CASTLE:
			return Vector2i(3, 1)  # Castle floor
		_:
			return Vector2i(0, 1)

func _get_door_tile_coords(level_type: LevelType) -> Vector2i:
	match level_type:
		LevelType.CAVE:
			return Vector2i(0, 2)  # Cave door
		LevelType.CATACOMB:
			return Vector2i(1, 2)  # Stone door
		LevelType.CRYPT:
			return Vector2i(2, 2)  # Crypt door
		LevelType.CASTLE:
			return Vector2i(3, 2)  # Castle door
		_:
			return Vector2i(0, 2)

# Get room at position
func get_room_at_position(pos: Vector2) -> Room:
	var tile_pos = Vector2(pos.x / TILE_SIZE, pos.y / TILE_SIZE)
	
	for room in rooms:
		if room.get_bounds().has_point(tile_pos):
			return room
	
	return null

# Check if position is valid floor
func is_valid_floor_position(pos: Vector2) -> bool:
	var tile_pos = Vector2(int(pos.x / TILE_SIZE), int(pos.y / TILE_SIZE))
	
	if tile_pos.x < 0 or tile_pos.x >= level_width or tile_pos.y < 0 or tile_pos.y >= level_height:
		return false
	
	return level_data[tile_pos.x][tile_pos.y] == FLOOR_TILE

# Get random floor position
func get_random_floor_position() -> Vector2:
	var attempts = 0
	var max_attempts = 100
	
	while attempts < max_attempts:
		attempts += 1
		var x = randi_range(0, level_width - 1)
		var y = randi_range(0, level_height - 1)
		
		if level_data[x][y] == FLOOR_TILE:
			return Vector2(x * TILE_SIZE, y * TILE_SIZE)
	
	# Fallback to center
	return Vector2(level_width * TILE_SIZE / 2.0, level_height * TILE_SIZE / 2.0)

# Get enemy spawn points for a specific room
func get_enemy_spawns_for_room(room: Room) -> Array:
	var spawns = []
	
	for spawn_point in enemy_spawn_points:
		if room.get_bounds().has_point(Vector2(spawn_point.x / TILE_SIZE, spawn_point.y / TILE_SIZE)):
			spawns.append(spawn_point)
	
	return spawns 
