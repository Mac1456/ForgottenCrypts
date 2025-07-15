extends RigidBody2D
class_name MagicMissile

var damage: int = 20
var speed: float = 600.0
var lifetime: float = 2.0
var owner_id: int = -1

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
	
	# Create a small circle shape for collision
	var shape = CircleShape2D.new()
	shape.radius = 5.0
	$CollisionShape2D.shape = shape
	$Area2D/AreaCollision.shape = shape

func launch(direction: Vector2, launch_speed: float = 0.0):
	var final_speed = launch_speed if launch_speed > 0 else speed
	linear_velocity = direction.normalized() * final_speed

func _on_area_2d_body_entered(body):
	if body.has_method("take_damage") and body.get("player_id") != owner_id:
		body.take_damage(damage, owner_id)
		queue_free()

func _on_visibility_notifier_2d_screen_exited():
	queue_free()

func _on_lifetime_timeout():
	queue_free() 