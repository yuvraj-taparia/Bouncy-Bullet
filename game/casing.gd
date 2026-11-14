extends Sprite2D
## A spent shell casing that flips out of the gun and fades away. Purely visual.

const GRAVITY := 700.0

var velocity := Vector2.ZERO
var spin := 0.0
var _age := 0.0


func _ready() -> void:
	texture = load(SpriteSheets.GUNS + "particles/casings/PistolCasing.png")
	z_index = 2


func _process(delta: float) -> void:
	_age += delta
	velocity.y += GRAVITY * delta
	position += velocity * delta
	rotation += spin * delta
	modulate.a = clampf(1.2 - _age * 1.5, 0.0, 1.0)
	if _age > 0.8:
		queue_free()
