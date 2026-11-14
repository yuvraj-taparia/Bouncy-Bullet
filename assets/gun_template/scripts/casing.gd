extends Sprite2D

const MAX_CASING = 60;
static var casingCount : int = 0;

@export var maxHeight : float = 50;
@export var rotDegrees : float = 35;
@export var speed : float = 150;
@export var gravity : float = 20;
@export var vspMax : float = -400;
@export_range(0, 1) var friction : float = 0.7;
@export var killTime : float = 3;
var killTimer = killTime;

@onready var shadowHeight = global_position.y + maxHeight; # + is down
@onready var vsp = vspMax * 0.6;

func _ready():
	# Count number of casing so we can limit the maximum
	casingCount += 1;

	# ShadowHeight
	# So like the casing will fly up then fall down
	# when it is greater or equals to shadowHeight
	# it will bounce up
	shadowHeight += randf_range(-1, 1) * 10;
	# Horizontal speed
	speed *= -sign(scale.x) * randf_range(0.7, 1.4);
	# Vertical speed
	vspMax *= randf_range(0.7, 1.4);

func _exit_tree() -> void:
	casingCount -= 1;

func _process(delta):
	killTimer -= delta;
	if (killTimer <= 0 || casingCount >= MAX_CASING): queue_free();
	if (is_zero_approx(vspMax)): return;
	
	rotation_degrees += rotDegrees;
	position.x += speed * delta;
	position.y += vsp * delta;
	vsp += gravity;
	if (global_position.y >= shadowHeight):
		# Add friction so it slows down when it hits the ground
		vspMax *= friction;
		speed *= friction;
		vsp = vspMax;
		rotDegrees *= friction;

	
