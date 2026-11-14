class_name Bullet
extends Node2D
## A bullet that ricochets off terrain. Once it has bounced it can hit the
## player who fired it and knock them along its path ("bounce back").

const SPEED := 650.0
const KNOCKBACK := 230.0

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
	_sprite.scale = Vector2(0.5, 0.5)
	_sprite.modulate = tint
	add_child(_sprite)
	rotation = direction.angle()


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
			SpriteSheets.spawn_fx(get_parent(), SpriteSheets.impact(), hit.position, direction.angle())
			queue_free()
			return

		remaining -= global_position.distance_to(hit.position)
		var normal: Vector2 = hit.normal
		global_position = hit.position + normal * 0.5
		SpriteSheets.spawn_fx(get_parent(), SpriteSheets.impact(), hit.position, normal.angle())
		bounces += 1
		if bounces > max_bounces:
			queue_free()
			return
		direction = direction.bounce(normal)

	rotation = direction.angle()
