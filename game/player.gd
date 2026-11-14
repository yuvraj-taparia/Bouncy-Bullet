class_name Player
extends CharacterBody2D
## Recoil platformer hero. Walk with A/D; aim with the mouse; every shot of the
## Desert Eagle kicks you the opposite way. Shots refill when you land.

signal ammo_changed(ammo: int, max_ammo: int)
signal fired

const GRAVITY := 900.0
const WALK_SPEED := 100.0
const GROUND_ACCEL := 900.0
const AIR_ACCEL := 260.0
const RECOIL := 360.0
const MAX_SPEED := 620.0
const MAX_AMMO := 3
const FIRE_COOLDOWN := 0.22

const CasingScript := preload("res://game/casing.gd")

@onready var body = $Body
@onready var gun: Node2D = $Gun
@onready var gun_sprite: AnimatedSprite2D = $Gun/Sprite
@onready var muzzle: Marker2D = $Gun/Muzzle
@onready var camera: Camera2D = $Camera2D

var ammo := MAX_AMMO
var frozen := false
var _cooldown := 0.0
var _reloading := false
var _shake := 0.0
var _was_on_floor := true


func _ready() -> void:
	ensure_input_actions()
	gun_sprite.sprite_frames = SpriteSheets.desert_eagle()
	gun_sprite.play(&"idle")
	gun_sprite.animation_finished.connect(_on_gun_animation_finished)


func _physics_process(delta: float) -> void:
	var aim := (get_global_mouse_position() - gun.global_position).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT * body.facing
	_point_gun(aim)

	velocity.y += GRAVITY * delta
	var input := 0.0 if frozen else Input.get_axis(&"move_left", &"move_right")

	if is_on_floor():
		velocity.x = move_toward(velocity.x, input * WALK_SPEED, GROUND_ACCEL * delta)
	elif input != 0.0 and (absf(velocity.x) < WALK_SPEED or signf(velocity.x) != signf(input)):
		# Steer a little in the air without cancelling a big recoil launch.
		velocity.x = move_toward(velocity.x, input * WALK_SPEED, AIR_ACCEL * delta)

	_cooldown -= delta
	if not frozen and Input.is_action_just_pressed(&"shoot"):
		var hovered_control := get_viewport().gui_get_hovered_control()
		if _cooldown <= 0.0 and not hovered_control is BaseButton:
			_shoot(aim)

	move_and_slide()

	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		_squash(Vector2(1.3, 0.75))
	_was_on_floor = on_floor
	if on_floor and ammo < MAX_AMMO and not _reloading:
		_start_reload()

	_update_shake(delta)


func _point_gun(aim: Vector2) -> void:
	gun.rotation = aim.angle()
	var facing := -1 if aim.x < 0.0 else 1
	gun.scale.y = facing
	body.facing = facing


func _shoot(aim: Vector2) -> void:
	if ammo <= 0:
		return
	ammo -= 1
	_cooldown = FIRE_COOLDOWN
	_reloading = false

	# Stop any motion toward where we're aiming, then kick the other way.
	var along := velocity.dot(aim)
	if along > 0.0:
		velocity -= aim * along
	velocity += -aim * RECOIL
	velocity = velocity.limit_length(MAX_SPEED)

	gun_sprite.play(&"shoot")
	gun_sprite.frame = 0
	var world := get_parent()
	SpriteSheets.spawn_fx(world, SpriteSheets.muzzle_flash(), muzzle.global_position, aim.angle(), Vector2(12, 0))

	var bullet := Bullet.new()
	bullet.direction = aim
	bullet.shooter = self
	world.add_child(bullet)
	bullet.global_position = muzzle.global_position

	var casing := Sprite2D.new()
	casing.set_script(CasingScript)
	world.add_child(casing)
	casing.global_position = gun.global_position
	casing.velocity = Vector2(-aim.x * 60.0 + randf_range(-20, 20), -150.0 + randf_range(-30, 0))
	casing.spin = randf_range(-20.0, 20.0)

	_squash(Vector2(0.85, 1.15))
	_shake = 3.0
	ammo_changed.emit(ammo, MAX_AMMO)
	fired.emit()


func _start_reload() -> void:
	_reloading = true
	gun_sprite.play(&"reload")


func _on_gun_animation_finished() -> void:
	if gun_sprite.animation == &"reload" and _reloading:
		_reloading = false
		ammo = MAX_AMMO
		ammo_changed.emit(ammo, MAX_AMMO)
	gun_sprite.play(&"idle")


## Called by a ricocheting bullet that comes back and hits us.
func hit_by_own_bullet(push: Vector2) -> void:
	velocity = (velocity + push).limit_length(MAX_SPEED)
	_shake = 4.0
	_squash(Vector2(1.2, 0.85))


func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	ammo = MAX_AMMO
	_reloading = false
	gun_sprite.play(&"idle")
	camera.reset_smoothing()
	ammo_changed.emit(ammo, MAX_AMMO)


func _squash(amount: Vector2) -> void:
	body.scale = amount
	var tween := create_tween()
	tween.tween_property(body, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_shake(delta: float) -> void:
	_shake = move_toward(_shake, 0.0, 20.0 * delta)
	camera.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))


## Registers the controls in code so they work without editing Project Settings.
static func ensure_input_actions() -> void:
	_add_keys(&"move_left", [KEY_A, KEY_LEFT])
	_add_keys(&"move_right", [KEY_D, KEY_RIGHT])
	_add_keys(&"restart", [KEY_R])
	if not InputMap.has_action(&"shoot"):
		InputMap.add_action(&"shoot")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event(&"shoot", click)


static func _add_keys(action: StringName, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
