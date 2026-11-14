class_name PixelArt
extends RefCounted
## Small hand-drawn pixel bits for the menus: hand cursor, coin, padlock,
## check mark, sparkles and the chunky yellow-orange title text.

const FONT := preload("res://ui/fonts/Silkscreen-Regular.ttf")

const INK := Color("1a1c2c")          ## dark navy outline used everywhere
const GOLD := Color("ffd23f")         ## title text fill
const EMBER := Color("f0641e")        ## title text drop
const COIN_RIM := Color(0.44, 0.22, 0.15)
const COIN_FACE := Color(1, 0.71, 0.21)
const COIN_SHINE := Color(1, 0.94, 0.59)

const HAND := [
	"....##......",
	"...#oo#.....",
	"...#oo#.....",
	"...#oo#.....",
	"...#oo###...",
	"...#oo#oo##.",
	".###oo#oo#o#",
	"#oo#ooooo#o#",
	"#oooooooooo#",
	".#ooooooooo#",
	"..#oooooooo#",
	"..#ooooooo#.",
	"...#oooooo#.",
	"...########.",
]

static var _hand: ImageTexture


## Pixel pointing-hand used for every clickable button.
static func install_hand_cursor() -> void:
	if _hand == null:
		var px := 3
		var img := Image.create(HAND[0].length() * px, HAND.size() * px, false, Image.FORMAT_RGBA8)
		for y in HAND.size():
			for x in HAND[y].length():
				var ch: String = HAND[y][x]
				if ch == ".":
					continue
				img.fill_rect(Rect2i(x * px, y * px, px, px), INK if ch == "#" else Color.WHITE)
		_hand = ImageTexture.create_from_image(img)
	Input.set_custom_mouse_cursor(_hand, Input.CURSOR_POINTING_HAND, Vector2(5 * 3, 1 * 3))


static func draw_coin(ci: CanvasItem, center: Vector2, s := 2.0) -> void:
	ci.draw_rect(Rect2(center + Vector2(-3, -8) * s, Vector2(6, 16) * s), COIN_RIM)
	ci.draw_rect(Rect2(center + Vector2(-6, -6) * s, Vector2(12, 12) * s), COIN_RIM)
	ci.draw_rect(Rect2(center + Vector2(-3, -6) * s, Vector2(6, 12) * s), COIN_FACE)
	ci.draw_rect(Rect2(center + Vector2(-4, -4) * s, Vector2(8, 8) * s), COIN_FACE)
	ci.draw_rect(Rect2(center + Vector2(-2, -4) * s, Vector2(2, 7) * s), COIN_SHINE)


static func draw_lock(ci: CanvasItem, center: Vector2, s := 2.0) -> void:
	var o := center + Vector2(-6, -7) * s
	# shackle
	ci.draw_rect(Rect2(o + Vector2(2, 0) * s, Vector2(8, 7) * s), INK)
	ci.draw_rect(Rect2(o + Vector2(3, 1) * s, Vector2(6, 1) * s), Color("b0b8c8"))
	ci.draw_rect(Rect2(o + Vector2(3, 1) * s, Vector2(1, 6) * s), Color("b0b8c8"))
	ci.draw_rect(Rect2(o + Vector2(8, 1) * s, Vector2(1, 6) * s), Color("b0b8c8"))
	# body
	ci.draw_rect(Rect2(o + Vector2(0, 6) * s, Vector2(12, 9) * s), INK)
	ci.draw_rect(Rect2(o + Vector2(1, 7) * s, Vector2(10, 7) * s), Color("e8a33d"))
	ci.draw_rect(Rect2(o + Vector2(1, 7) * s, Vector2(10, 1) * s), Color("ffd27a"))
	ci.draw_rect(Rect2(o + Vector2(5, 9) * s, Vector2(2, 3) * s), INK)


static func draw_check(ci: CanvasItem, origin: Vector2, s := 2.0, color := Color.WHITE) -> void:
	var pts := [Vector2(0, 3), Vector2(1, 4), Vector2(2, 5), Vector2(3, 4), Vector2(4, 3), Vector2(5, 2), Vector2(6, 1)]
	for p in pts:
		ci.draw_rect(Rect2(origin + (p + Vector2(-1, -1)) * s, Vector2(3, 3) * s), INK)
	for p in pts:
		ci.draw_rect(Rect2(origin + p * s, Vector2(s, s) * 1.0), color)


## A 4-point pixel twinkle; `phase` 0..1 grows then shrinks it.
static func draw_sparkle(ci: CanvasItem, center: Vector2, phase: float, s := 2.0) -> void:
	var size := roundi(sin(phase * PI) * 3.0)
	if size <= 0:
		return
	var c := center.round()
	ci.draw_rect(Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), Color.WHITE)
	for i in range(1, size + 1):
		var col := GOLD if i < size else Color(1, 0.95, 0.6, 0.8)
		for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			ci.draw_rect(Rect2(c + d * i * s - Vector2(s, s) * 0.5, Vector2(s, s)), col)


## Chunky title text: dark outline, orange drop, yellow face.
static func draw_title_text(ci: CanvasItem, text: String, pos: Vector2, size: int, align := HORIZONTAL_ALIGNMENT_CENTER, width := -1.0) -> void:
	var drop := maxf(2.0, size / 8.0)
	ci.draw_string_outline(FONT, pos + Vector2(0, drop), text, align, width, size, maxi(4, size / 4), INK)
	ci.draw_string_outline(FONT, pos, text, align, width, size, maxi(4, size / 4), INK)
	ci.draw_string(FONT, pos + Vector2(0, drop), text, align, width, size, EMBER)
	ci.draw_string(FONT, pos, text, align, width, size, GOLD)


## Label in the menu style (Silkscreen, light text, navy outline).
static func label(text: String, size: int, color := Color(1, 0.97, 0.84)) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", maxi(4, size / 3))
	return l
