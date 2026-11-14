class_name PopButton
extends Control
## A button laid exactly over a button that is painted into a mockup image.
## Idle it looks identical to the painting. On hover/focus it "pops out":
## lifts a few pixels, brightens, drops a thick dark shadow, sparkles and
## shows a pointer arrow. It can also paint its own face (EQUIP / EQUIPPED).

signal pressed

enum Face { TEXTURE, EQUIP, EQUIPPED }

const LIFT := 3.0

var texture: Texture2D          ## crop of the painted button
var face := Face.TEXTURE:
	set(value):
		face = value
		queue_redraw()
var locked := false:
	set(value):
		locked = value
		queue_redraw()
var badge_check := false         ## small green check (e.g. cleared level)
var show_arrow := true
var sparkle_count := 4

var _lift := 0.0
var _press := 0.0
var _hovered := false
var _time := 0.0
var _shake := 0.0
var _lift_tween: Tween


func _init(tex: Texture2D = null, rect := Rect2()) -> void:
	texture = tex
	position = rect.position
	size = rect.size
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_update_lift)
	focus_exited.connect(_update_lift)


## Crops `rect` out of `image` and lays a PopButton exactly on top of it.
static func over(image: Texture2D, rect: Rect2) -> PopButton:
	var crop := AtlasTexture.new()
	crop.atlas = image
	crop.region = rect
	return PopButton.new(crop, rect)


func is_active() -> bool:
	return has_focus() or _hovered


## Small "no" wiggle, e.g. when a level is locked or you can't afford a gun.
func shake() -> void:
	_shake = 1.0


## Briefly pop up and back down (used for the menu intro).
func hop(delay := 0.0) -> void:
	var t := create_tween()
	t.tween_interval(delay)
	t.tween_property(self, "_lift", 2.5, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "_lift", 0.0, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_callback(_update_lift)


func _on_mouse_entered() -> void:
	_hovered = true
	if not has_focus():
		grab_focus()
	_update_lift()


func _on_mouse_exited() -> void:
	_hovered = false
	_update_lift()


func _update_lift() -> void:
	var target := 1.0 if is_active() and not locked else 0.0
	if _lift_tween:
		_lift_tween.kill()
	_lift_tween = create_tween()
	_lift_tween.tween_property(self, "_lift", target, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press = 1.0
		elif _press > 0.0:
			_press = 0.0
			if Rect2(Vector2.ZERO, size).has_point(event.position):
				_activate()
		accept_event()
	elif event.is_action_pressed(&"ui_accept"):
		_activate()
		accept_event()


func _activate() -> void:
	if locked:
		shake()
	pressed.emit()


func _process(delta: float) -> void:
	_time += delta
	_shake = move_toward(_shake, 0.0, delta * 3.0)
	queue_redraw()


func _draw() -> void:
	var shake_x := sin(_time * 60.0) * 3.0 * _shake
	var lift := LIFT * _lift - _press * 1.0
	var face_rect := Rect2(Vector2(shake_x, -lift), size)

	if _lift > 0.01 or _shake > 0.0:
		# Thick dark shadow under the raised button.
		var shadow := Rect2(Vector2(shake_x + 2.0 * _lift, 3.0 * _lift), size)
		_draw_face_silhouette(shadow, Color(0.04, 0.04, 0.1, 0.75 * clampf(_lift, 0.0, 1.0)))

	var bright := 1.0 + 0.22 * clampf(_lift, 0.0, 1.0)
	_draw_face(face_rect, Color(bright, bright, bright * 0.95))

	if locked:
		draw_rect(face_rect.grow(-3), Color(0.05, 0.06, 0.12, 0.62))
		PixelArt.draw_lock(self, face_rect.get_center() + Vector2(0, 2), 2.0)
	if badge_check:
		var b := face_rect.position + Vector2(size.x - 14, 4)
		draw_rect(Rect2(b - Vector2(3, 3), Vector2(18, 16)), PixelArt.INK)
		draw_rect(Rect2(b - Vector2(1, 1), Vector2(14, 12)), Color("3aa845"))
		PixelArt.draw_check(self, b + Vector2(1, 0), 1.5)

	if _lift > 0.5 and not locked:
		_draw_sparkles(face_rect)
		if show_arrow:
			_draw_arrow(Vector2(face_rect.end.x + 8 + sin(_time * 8.0) * 3.0, face_rect.get_center().y))


func _draw_face(r: Rect2, tint: Color) -> void:
	match face:
		Face.TEXTURE:
			if texture:
				draw_texture_rect(texture, r, false, tint)
		Face.EQUIP:
			_draw_plate(r, Color("f2c14e") * tint, Color("ffe69a") * tint, Color("b9772a"))
			PixelArt.draw_title_text(self, "EQUIP", Vector2(r.position.x, r.get_center().y + 7), 20, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Face.EQUIPPED:
			_draw_plate(r, Color("3fbf4f"), Color("8ef07a"), Color("23803a"))
			var font := PixelArt.FONT
			var text_pos := Vector2(r.position.x + 6, r.get_center().y + 5)
			draw_string_outline(font, text_pos, "EQUIPPED", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, PixelArt.INK)
			draw_string(font, text_pos, "EQUIPPED", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
			PixelArt.draw_check(self, Vector2(r.end.x - 18, r.get_center().y - 4), 1.5)


func _draw_face_silhouette(r: Rect2, color: Color) -> void:
	if face == Face.TEXTURE and texture:
		draw_texture_rect(texture, r, false, color)
	else:
		draw_rect(r, color)


## Flat chunky plate: navy outline, coloured body, light top edge, dark base.
func _draw_plate(r: Rect2, body: Color, light: Color, dark: Color) -> void:
	draw_rect(r, PixelArt.INK)
	var inner := r.grow(-3)
	draw_rect(inner, body)
	draw_rect(Rect2(inner.position, Vector2(inner.size.x, 3)), light)
	draw_rect(Rect2(inner.position.x, inner.end.y - 4, inner.size.x, 4), dark)


func _draw_sparkles(r: Rect2) -> void:
	var spots := [
		r.position + Vector2(6, 4), Vector2(r.end.x - 8, r.position.y + 6),
		Vector2(r.end.x - 4, r.end.y - 8), Vector2(r.position.x + 10, r.end.y - 5),
		Vector2(r.get_center().x, r.position.y + 2),
	]
	for i in mini(sparkle_count, spots.size()):
		var phase := fposmod(_time * 1.6 + i * 0.37, 1.0)
		PixelArt.draw_sparkle(self, spots[i], phase, 2.0)


func _draw_arrow(tip_left: Vector2) -> void:
	# ▶ pointer: navy outline, gold fill.
	var p := tip_left.round()
	for i in 8:
		draw_rect(Rect2(p + Vector2(i * 2 - 2, -9 + i), Vector2(4, 18 - i * 2 + 2)), PixelArt.INK)
	for i in 6:
		draw_rect(Rect2(p + Vector2(i * 2, -6 + i), Vector2(2, 12 - i * 2)), PixelArt.GOLD)
