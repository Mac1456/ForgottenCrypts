extends RigidBody2D
class_name Meteor

var damage: int = 50
var speed: float = 300.0
var lifetime: float = 4.0
var owner_id: int = -1
var aoe_radius: float = 60.0

func _ready():
	# Set up the projectile
	gravity_scale = 0.0
	linear_damp = 0.0
	
	# Auto-destroy after lifetime
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(_on_lifetime_timeout)
	add_child(timer)
	timer.start()
	
	# Create a larger circle shape for collision
	var shape = CircleShape2D.new()
	shape.radius = 12.0
	$CollisionShape2D.shape = shape
	$Area2D/AreaCollision.shape = shape

func launch(direction: Vector2, launch_speed: float = 0.0):
	var final_speed = launch_speed if launch_speed > 0 else speed
	linear_velocity = direction.normalized() * final_speed

func _on_area_2d_body_entered(body):
	if body.has_method("take_damage") and body.get("player_id") != owner_id:
		# AoE damage - affect all nearby enemies
		explode()

func explode():
	# Create explosion effect (simple AoE damage)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = aoe_radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var body = result.collider
		if body.has_method("take_damage") and body.get("player_id") != owner_id:
			body.take_damage(damage, owner_id)
	
	queue_free()

func _on_visibility_notifier_2d_screen_exited():
	queue_free()

func _on_lifetime_timeout():
	queue_free() 