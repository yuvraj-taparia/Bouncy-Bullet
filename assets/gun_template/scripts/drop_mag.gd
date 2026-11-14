extends Sprite2D

@export var maxHeight : float = 40;
@export var gravity : float = 20;
@export var maxSpeed : Vector2 = Vector2(150, -200);
@export var killTime : float = 4;
@export var maxRot : float = 20;
@onready var killTimer : float = killTime;
var shadowHeight : float = 0;
var velocity : Vector2 = Vector2.ZERO;
var rot : float = 0;


# Read casing.gd

func _ready():
	maxRot *= randf_range(0.8, 1.2);
	maxSpeed *= randf_range(0.8, 1.2);
	shadowHeight = global_position.y + maxHeight;
	pass # Replace with function body.


func _process(delta):
	killTimer -= delta;
	if (killTimer <= 0):
		queue_free(); 
	if (is_zero_approx(maxRot)):
		return;
	position += velocity * delta;
	velocity.x *= 0.9;
	velocity.y += gravity;
	rotation_degrees += rot;
	# Only rotate when it hits the ground
	# I don't know why but it looks cooler
	rot = lerpf(rot, 0, 7 * delta);
	if (global_position.y >= shadowHeight):
		maxSpeed.x *= 0.7;
		maxSpeed.y *= 0.76;
		maxRot *= 0.8;
		rot = maxRot;
		velocity.x += maxSpeed.x;
		velocity.y = maxSpeed.y;
	pass
