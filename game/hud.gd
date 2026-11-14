extends CanvasLayer
## Ammo pips, run timer, control hint and the win screen. Built in code.

const TEXT := Color(1, 0.97, 0.84)
const OUTLINE := Color(0.1, 0.13, 0.23)

var _ammo_icons: Array[TextureRect] = []
var _time_label: Label
var _coin_label: Label
var _hint: Label
var _win: Label


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(root)

	var ammo_box := HBoxContainer.new()
	ammo_box.position = Vector2(20, 16)
	ammo_box.add_theme_constant_override("separation", 6)
	root.add_child(ammo_box)
	var bullet_icon := AtlasTexture.new()
	bullet_icon.atlas = load(SpriteSheets.GUNS + "bullet.png")
	bullet_icon.region = Rect2(22, 2, 22, 12)
	for i in Player.MAX_AMMO:
		var icon := TextureRect.new()
		icon.texture = bullet_icon
		icon.custom_minimum_size = Vector2(44, 24)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ammo_box.add_child(icon)
		_ammo_icons.append(icon)

	_time_label = _make_label(root, 22)
	_time_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_time_label.offset_left = -200
	_time_label.offset_right = -20
	_time_label.offset_top = 14
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_coin_label = _make_label(root, 16)
	_coin_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_coin_label.offset_left = -200
	_coin_label.offset_right = -20
	_coin_label.offset_top = 44
	_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_hint = _make_label(root, 18)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_left = -500
	_hint.offset_right = 500
	_hint.offset_top = -48
	_hint.offset_bottom = -16
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.text = "A / D walk   ·   Click to shoot — the kick throws you the other way   ·   3 shots, refill on landing   ·   R restart"

	_win = _make_label(root, 34)
	_win.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_win.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_win.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_win.visible = false


func _make_label(parent: Control, size: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", TEXT)
	label.add_theme_color_override("font_outline_color", OUTLINE)
	label.add_theme_constant_override("outline_size", 8)
	parent.add_child(label)
	return label


func set_ammo(ammo: int, _max_ammo: int) -> void:
	for i in _ammo_icons.size():
		_ammo_icons[i].modulate = Color(1, 1, 1, 1) if i < ammo else Color(0.25, 0.25, 0.3, 0.6)


func set_time(seconds: float) -> void:
	_time_label.text = "%.1f s" % seconds


func set_coins(collected: int, total: int) -> void:
	_coin_label.text = "Coins %d/%d" % [collected, total]


func show_win(seconds: float, shots: int, splashes: int) -> void:
	_hint.visible = false
	_win.visible = true
	_win.text = "SAFEZONE REACHED!\n\n%.1f seconds   ·   %d shots   ·   %d splashes\n\nPress R to play again" % [seconds, shots, splashes]
