extends Area2D

signal player_touched(body: Node2D)

enum State { PATROL, ATTACK, HIT, DEFEATED }

const FROG_HOP_DURATION := 0.9
const FROG_HOP_HEIGHT := 12.0

const PATROLS := {
	"beaver": [&"idle", &"walk"],
	"frog": [&"idle_1", &"jump", &"jump_idle", &"jump_landing", &"idle_2"],
	"molerat": [&"idle", &"walk", &"roll_start", &"roll_idle", &"roll_stop"],
	"worm": [&"idle", &"walk", &"hide", &"appear"],
	"rhino": [&"idle", &"walk"],
	"shoebill": [&"idle", &"walk", &"egg_lays"],
	"shoebill_chick": [&"idle", &"walk"],
	"bat": [&"idle"],
	"dragonfly": [&"idle"],
}
const FALLBACK_COLORS := {
	"beaver": Color("#925147"),
	"frog": Color("#58b768"),
	"molerat": Color("#b68684"),
	"worm": Color("#bc718f"),
	"rhino": Color("#8b889f"),
	"shoebill": Color("#6c839b"),
	"shoebill_chick": Color("#e3a75a"),
	"bat": Color("#9279af"),
	"dragonfly": Color("#5ca9b4"),
}
const ATTACKS := {
	"beaver": [&"attack_1", &"attack_2"],
	"frog": [&"attack_1"],
	"molerat": [&"attack_1"],
	"worm": [&"attack_1"],
	"rhino": [&"attack_1", &"attack_2", &"attack_3"],
	"shoebill": [&"attack"],
	"shoebill_chick": [&"kamikaze"],
	"bat": [&"attack_1", &"attack_2"],
	"dragonfly": [&"attack_1", &"attack_2"],
}

@export var animation_path: String
@export var patrol := Vector2.ZERO
@export var patrol_speed := 2.0
@export var hit_points := 1

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox: CollisionShape2D = $CollisionShape2D
@onready var glow: Sprite2D = $Glow

var origin: Vector2
var phase := 0.0
var species: String
var state := State.PATROL
var patrol_index := 0
var attack_index := 0
var attack_cooldown := 0.0
var hatching := false
var frog_hop_time := FROG_HOP_DURATION


func _ready() -> void:
	origin = position
	species = animation_path.get_file().get_basename()
	if ResourceLoader.exists(animation_path, "SpriteFrames"):
		sprite.sprite_frames = load(animation_path)
	else:
		sprite.sprite_frames = _fallback_frames()
		var dimensions: Vector2 = hitbox.shape.size
		sprite.scale = dimensions / Vector2(16, 16)
		sprite.position = hitbox.position - dimensions * 0.5
	sprite.animation_finished.connect(_on_animation_finished)
	glow.position = hitbox.position
	glow.scale.x = maxf(1.0, hitbox.shape.size.x / 24.0)
	glow.show()
	hatching = species == "shoebill_chick"
	if hatching:
		sprite.play(&"egg_idle")
	else:
		_play_patrol()


func _fallback_frames() -> SpriteFrames:
	var color: Color = FALLBACK_COLORS[species]
	var idle := _fallback_texture(color, 0)
	var raised := _fallback_texture(color, 1)
	var hurt := _fallback_texture(Color("#e47a63"), 0)
	var frames := SpriteFrames.new()
	var clips: Array = PATROLS[species] + ATTACKS[species] + [
		&"egg_idle", &"out_of_an_egg", &"hurt", &"hit", &"hit_test", &"dead",
	]
	for clip in clips:
		frames.add_animation(clip)
		frames.set_animation_loop(clip, false)
		if clip in [&"hurt", &"hit", &"hit_test", &"dead"]:
			frames.set_animation_speed(clip, 8)
			frames.add_frame(clip, hurt)
		else:
			frames.set_animation_speed(clip, 5)
			frames.add_frame(clip, idle)
			frames.add_frame(clip, raised)
	return frames


func _fallback_texture(color: Color, lift: int) -> ImageTexture:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var outline := Color("#2a2039")
	image.fill_rect(Rect2i(5, 4 - lift, 10, 10), outline)
	image.fill_rect(Rect2i(1, 7, 12, 7), outline)
	image.fill_rect(Rect2i(3, 8, 8, 5), color.darkened(0.12))
	image.fill_rect(Rect2i(6, 5 - lift, 8, 7), color)
	image.fill_rect(Rect2i(11, 6 - lift, 2, 2), Color("#fff3ca"))
	image.set_pixel(12, 6 - lift, outline)
	image.fill_rect(Rect2i(4, 12 - lift, 2, 3), outline)
	image.fill_rect(Rect2i(11, 12, 2, 3 - lift), outline)
	return ImageTexture.create_from_image(image)


func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if not hatching and state == State.PATROL and attack_cooldown == 0.0:
		var player := get_tree().get_first_node_in_group(&"player") as Player
		if is_instance_valid(player) and not player.frozen:
			var distance := player.global_position - Vector2(0, 10) - hitbox.global_position
			if absf(distance.x) < hitbox.shape.size.x * 0.5 + 24.0 and absf(distance.y) < 26.0:
				_attack(distance.x)
	var moving := not hatching and (state == State.PATROL or (
		state == State.ATTACK and sprite.animation == &"kamikaze"
	))
	var follows_patrol := patrol.y != 0.0 or sprite.animation in [
		&"walk", &"roll_idle", &"jump", &"jump_idle", &"kamikaze",
	]
	if moving and follows_patrol:
		phase += delta * patrol_speed
	var next_position := origin + patrol * sin(phase)
	# Finish the current arc even if an attack or hit interrupts the jump clip.
	if frog_hop_time < FROG_HOP_DURATION:
		frog_hop_time = minf(frog_hop_time + delta, FROG_HOP_DURATION)
		next_position.y -= FROG_HOP_HEIGHT * sin(frog_hop_time / FROG_HOP_DURATION * PI)
	if state == State.PATROL and not is_equal_approx(next_position.x, position.x):
		sprite.flip_h = next_position.x < position.x
	position = next_position


func _play_patrol() -> void:
	state = State.PATROL
	var clips: Array = PATROLS[species]
	var clip: StringName = clips[patrol_index]
	if clip == &"jump" and frog_hop_time >= FROG_HOP_DURATION:
		frog_hop_time = 0.0
	sprite.play(clip)
	patrol_index = (patrol_index + 1) % clips.size()


func _attack(direction: float) -> void:
	state = State.ATTACK
	var clips: Array = ATTACKS[species]
	sprite.flip_h = direction < 0.0
	sprite.play(clips[attack_index])
	attack_index = (attack_index + 1) % clips.size()


func _on_animation_finished() -> void:
	if state == State.DEFEATED:
		if sprite.animation == &"dead":
			queue_free()
		else:
			_play_defeat()
	elif hatching and state == State.PATROL:
		if sprite.animation == &"egg_idle":
			sprite.play(&"out_of_an_egg")
		else:
			hatching = false
			_play_patrol()
	else:
		if state == State.ATTACK:
			attack_cooldown = 0.6
			if sprite.animation == &"kamikaze":
				queue_free()
				return
		_play_patrol()


func _on_body_entered(body: Node2D) -> void:
	if state != State.DEFEATED and body.is_in_group(&"player"):
		if state == State.PATROL and not hatching and attack_cooldown == 0.0:
			_attack(body.global_position.x - global_position.x)
		player_touched.emit(body)


func hit() -> void:
	if state == State.DEFEATED:
		return
	var interrupted_attack := state == State.ATTACK
	hit_points -= 1
	if hit_points <= 0:
		state = State.DEFEATED
		collision_layer = 0
		set_deferred("monitoring", false)
		glow.hide()
	else:
		state = State.HIT
		sprite.modulate = Color(0.86, 0.77, 0.67)
	var reaction := &"hurt" if species == "bat" else &"hit"
	if species == "dragonfly" and interrupted_attack:
		reaction = &"hit_test"
	if sprite.sprite_frames.has_animation(reaction):
		sprite.stop()
		sprite.play(reaction)
	elif state == State.DEFEATED:
		_play_defeat()
	else:
		_play_patrol()


func _play_defeat() -> void:
	if sprite.sprite_frames.has_animation(&"dead"):
		sprite.play(&"dead")
	else:
		queue_free()
