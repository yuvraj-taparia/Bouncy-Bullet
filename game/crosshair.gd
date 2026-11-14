extends Node2D
## Pixel crosshair that follows the mouse (the system cursor is hidden).

const COLOR := Color(1, 1, 1, 0.95)
const SHADOW := Color(0.1, 0.13, 0.23, 0.9)


func _ready() -> void:
	z_index = 100
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(_delta: float) -> void:
	global_position = get_global_mouse_position().round()


func _draw() -> void:
	for pass_color in [SHADOW, COLOR]:
		var grow := 1.0 if pass_color == SHADOW else 0.0
		for rect in [Rect2(-1, -6, 2, 4), Rect2(-1, 2, 2, 4), Rect2(-6, -1, 4, 2), Rect2(2, -1, 4, 2)]:
			draw_rect(rect.grow(grow), pass_color)
	draw_rect(Rect2(-0.5, -0.5, 1, 1), COLOR)
