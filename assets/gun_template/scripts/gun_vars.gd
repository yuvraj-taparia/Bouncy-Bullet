extends Node2D
class_name GunVars

# Gun Prefabs Variables

var muzzleFlash : Sprite2D;
var showFlash : bool = true;
# Recoil Animation
@export var recoilRot : float = 0;
@export var recoilPosX : float = 0;
@export var recoilPosY : float = 0;
@export var posOffset : Vector2 = Vector2.ZERO;
# Where to put its upgrade
var laser : Line2D = null;
var casing : Marker2D = null;
var sight : Marker2D = null;
var mag : Marker2D = null;
var muzzle : Marker2D = null;
var stock : Marker2D = null;
var grip : Marker2D = null;
var fullAuto : Marker2D = null;
var dropMag : Marker2D = null;
var par;
var lastMuzzleTime : SceneTreeTimer;
@onready var animator = $AnimationTree;

func _ready():
	if (has_node("BulletSpawnPoint/MuzzleFlash")):
		muzzleFlash = $BulletSpawnPoint/MuzzleFlash;
	if (has_node("DropMag")):
		dropMag = $DropMag;
	if (has_node("gun/Casing")):
		casing = $gun/Casing;
	if (has_node("gun/Sight")):
		sight = $gun/Sight;
	if (has_node("gun/Magazine")):
		mag = $gun/Magazine;
	if (has_node("gun/Muzzle")):
		muzzle = $gun/Muzzle;
	if (has_node("gun/Stock")):
		stock = $gun/Stock;
	if (has_node("gun/Grip")):
		grip = $gun/Grip;
	if (has_node("gun/FullAuto")):
		fullAuto = $gun/FullAuto;
	if (has_node("gun/Laser")):
		laser = $gun/Laser;
		laser.visible = false;
	posOffset = position;
	par = get_parent();

func spawnCasing() -> void:
	par.spawn_casing();

func spawnMag() -> void:
	par.spawn_mag();

func EnableLaser() -> void:
	laser.visible = true;

func EnableMuzzleFlash() -> void:
	if (!showFlash): return;
	assert(muzzleFlash != null, "This gun doesn't have a muzzle Flash");
	muzzleFlash.frame = randi_range(0, muzzleFlash.hframes - 1);
	muzzleFlash.visible = true;
	lastMuzzleTime = get_tree().create_timer(0.04);
	await lastMuzzleTime.timeout;
	if (lastMuzzleTime.time_left <= 0):
		muzzleFlash.visible = false;

func playAudio(_name)-> void:
	pass;
