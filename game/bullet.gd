class_name Bullet
extends Node2D
## A bullet that ricochets off terrain. Once it has bounced it can hit the
## player who fired it and knock them along its path ("bounce back").

const SPEED := 650.0
const KNOCKBACK := 230.0
const IMPACT := preload("res://assets/gun_template/prefabs/impact_particle.tscn")
const LIGHT := preload("res://assets/pixel_art_guns/sprites/light.png")

var direction := Vector2.RIGHT
var shooter: CharacterBody2D
var max_bounces := 3
var lifetime := 1.6
var tint := Color.WHITE
var bounces := 0
var _age := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	z_index = 3
	_sprite = Sprite2D.new()
	_sprite.texture = load(SpriteSheets.GUNS + "bullet.png")
	_sprite.hframes = 2
	_sprite.frame = 1
	_sprite.scale = Vector2(0.75, 0.75)
	_sprite.modulate = tint
	add_child(_sprite)
	# Soft glow, as in the gun pack's bullet prefab.
	var glow := Sprite2D.new()
	glow.texture = LIGHT
	glow.self_modulate = Color(tint.r, tint.g * 0.89, tint.b * 0.25, 0.3)
	glow.scale = Vector2(0.75, 0.75)
	add_child(glow)
	rotation = direction.angle()


## The pack's impact spark, pointing away from the surface that was hit.
func _spark(at: Vector2, angle: float) -> void:
	var fx: Node2D = IMPACT.instantiate()
	fx.scale = Vector2.ONE
	get_parent().add_child(fx)
	fx.global_position = at
	fx.global_rotation = angle


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > lifetime:
		queue_free()
		return

	var space := get_world_2d().direct_space_state
	var remaining := SPEED * delta
	# A fast bullet can hit more than one surface in a frame, so step until
	# the distance for this frame is used up.
	for _step in 4:
		var target := global_position + direction * remaining
		var query := PhysicsRayQueryParameters2D.create(global_position, target, 1)
		if bounces == 0 and is_instance_valid(shooter):
			query.exclude = [shooter.get_rid()]
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			global_position = target
			break

		if hit.collider == shooter:
			shooter.hit_by_own_bullet(direction * KNOCKBACK)
			_spark(hit.position, direction.angle() + PI)
			queue_free()
			return

		remaining -= global_position.distance_to(hit.position)
		var normal: Vector2 = hit.normal
		global_position = hit.position + normal * 0.5
		_spark(hit.position, normal.angle())
		bounces += 1
		if bounces > max_bounces:
			queue_free()
			return
		direction = direction.bounce(normal)

	rotation = direction.angle()
