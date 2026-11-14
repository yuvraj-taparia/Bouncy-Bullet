class_name GunRig
extends Node2D
## Plays one of the template gun scenes from the gun pack
## (assets/gun_template/guns/*.tscn): its AnimationTree
## (pickup / idle / shoot / reload), the recoil kick animation, attachments,
## muzzle flash, ejected casings and the magazine that drops out on reload.
##
## The gun scenes' own script (gun_vars.gd) calls spawn_casing() and
## spawn_mag() on its parent during the animations, which is this node.

signal reload_finished

const CASING := preload("res://assets/gun_template/prefabs/casing.tscn")
const DROP_MAG := preload("res://assets/gun_template/prefabs/drop_mag.tscn")

var gun: Node2D          ## the template scene root (GunVars)
var spawn_point: Node2D  ## where bullets come out
var world: Node          ## where casings and dropped mags go
var data: Dictionary

var _tree: AnimationTree
var _recoil: AnimationPlayer
var _speed := 1.0
var _mag_scene: PackedScene
var _casing_texture: Texture2D
var _recoil_mult := Vector3.ONE
var _reload_steps: Array = []    ## [[animation, seconds], ...]
var _step_left := 0.0
var _shooting_flag := false


func setup(gun_data: Dictionary, world_node: Node) -> void:
	data = gun_data
	world = world_node
	gun = load(data.scene).instantiate()
	add_child(gun)
	spawn_point = gun.get_node("BulletSpawnPoint")
	_recoil = gun.get_node("RecoilAnimator")
	_tree = gun.get_node("AnimationTree")
	# We advance the tree ourselves so animations can be sped up to fit the
	# fast "reload when you land" rhythm of a platformer.
	_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_tree.active = true

	for marker in data.attachments:
		gun.get_node("gun/" + marker).add_child(load(data.attachments[marker]).instantiate())
	if data.mag != "":
		_mag_scene = load(data.mag)
		gun.get_node("gun/Magazine").add_child(_mag_scene.instantiate())
	_casing_texture = load(data.casing)

	_play(&"pickup", data.pickup_speed)


func _process(delta: float) -> void:
	if gun == null:
		return
	_tree.advance(delta * _speed)
	if _shooting_flag:
		_tree.set("parameters/conditions/shooting", false)
		_shooting_flag = false

	# Recoil: the recoil animation moves these numbers; apply them to the gun.
	gun.position = gun.posOffset + Vector2(gun.recoilPosX * _recoil_mult.y, gun.recoilPosY * _recoil_mult.z)
	gun.rotation_degrees = gun.recoilRot * _recoil_mult.x

	if not _reload_steps.is_empty():
		_step_left -= delta
		if _step_left <= 0.0:
			_reload_steps.pop_front()
			if _reload_steps.is_empty():
				reload_finished.emit()
			else:
				_start_reload_step()


## Replays the "pull out the gun" animation.
func pickup() -> void:
	cancel_reload()
	_play(&"pickup", data.pickup_speed)


## Gun sprite's centre in this rig's local space (attachments not counted).
func visual_center() -> Vector2:
	var sprite: Sprite2D = gun.get_node("gun")
	return gun.posOffset + sprite.get_rect().get_center()


func shoot() -> void:
	cancel_reload()
	var h: Dictionary = data.handling
	_recoil_mult = Vector3(randf_range(h.rot.x, h.rot.y), randf_range(h.x.x, h.x.y), randf_range(h.y.x, h.y.y))
	_recoil.stop()
	_recoil.speed_scale = data.recoil_speed
	_recoil.play(&"recoil")
	_tree.set("parameters/conditions/shooting", true)
	_shooting_flag = true
	_play(&"shoot", data.shoot_speed)


## Plays the reload animation(s), squeezed into `seconds` in total.
## Shotguns play: open -> one "shell in" per shell -> pump.
func reload(seconds: float, shells := 1) -> void:
	_reload_steps.clear()
	if _tree.has_animation(&"reload_bulletIn"):
		var parts := [[&"reload", 1.0]]
		for i in shells:
			parts.append([&"reload_bulletIn", 1.0])
		parts.append([&"reload_end", 1.0])
		var raw := 0.0
		for p in parts:
			raw += _tree.get_animation(p[0]).length
		for p in parts:
			p[1] = _tree.get_animation(p[0]).length / raw * seconds
		_reload_steps = parts
	else:
		_reload_steps = [[&"reload", seconds]]
	_start_reload_step()


func is_reloading() -> bool:
	return not _reload_steps.is_empty()


func cancel_reload() -> void:
	_reload_steps.clear()


func _start_reload_step() -> void:
	var step: Array = _reload_steps[0]
	_step_left = step[1]
	_play(step[0], _tree.get_animation(step[0]).length / maxf(step[1], 0.01))


func _play(anim: StringName, speed: float) -> void:
	if not _tree.has_animation(anim):
		return
	_speed = speed
	_tree.get("parameters/playback").start(anim, true)


func _facing() -> float:
	return signf(get_parent().scale.y) if get_parent() is Node2D else 1.0


## Called from the gun animation (via gun_vars.gd) when a shell is ejected.
func spawn_casing() -> void:
	if gun.casing == null or not is_instance_valid(world):
		return
	var casing: Sprite2D = CASING.instantiate()
	casing.texture = _casing_texture
	casing.position = gun.casing.global_position   # set before entering the tree: its script reads it in _ready
	casing.scale.x *= _facing()
	casing.z_index = 2
	world.add_child(casing)


## Called from the reload animation when the empty magazine falls out.
func spawn_mag() -> void:
	if gun.dropMag == null or _mag_scene == null or not is_instance_valid(world):
		return
	var mag: Sprite2D = DROP_MAG.instantiate()
	mag.add_child(_mag_scene.instantiate())
	mag.position = gun.dropMag.global_position
	mag.rotation = gun.dropMag.global_rotation
	mag.scale.x *= _facing()
	mag.z_index = 2
	world.add_child(mag)
