extends Node2D
## Placeholder pixel character drawn in code (the asset packs have no hero).
## Origin is at the feet. Swap this for a sprite when you have player art.

const SKIN := Color("f2c79b")
const SHIRT := Color("d9483b")
const PANTS := Color("2f3a5f")
const HAIR := Color("4a2f22")
const OUTLINE := Color("1a1c2c")

var facing := 1:
	set(value):
		if value != facing:
			facing = value
			queue_redraw()


func _draw() -> void:
	var f := float(facing)
	# outline
	draw_rect(Rect2(-6, -21, 12, 21), OUTLINE)
	# legs
	draw_rect(Rect2(-5, -6, 4, 6), PANTS)
	draw_rect(Rect2(1, -6, 4, 6), PANTS)
	# shirt
	draw_rect(Rect2(-5, -13, 10, 7), SHIRT)
	# head
	draw_rect(Rect2(-5, -20, 10, 7), SKIN)
	draw_rect(Rect2(-5, -20, 10, 2), HAIR)
	draw_rect(Rect2(-5 if facing > 0 else 3, -18, 2, 3), HAIR)
	# eye
	draw_rect(Rect2(1.0 * f + (0.0 if facing > 0 else -2.0), -17, 2, 2), OUTLINE)
