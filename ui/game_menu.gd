extends Node
## Menu flow:  Title  ->  Main menu  ->  Select level / Buy guns / Controls  ->  Level
##
## Each menu screen is one of the painted mockups in ui/mockups/. Real buttons
## (PopButton) sit exactly on top of the buttons painted in the picture, so
## the rectangles below are in the picture's own pixels (1024 x 572).

const LEVELS: Array[PackedScene] = [
	preload("res://maps/grassland/grassland.tscn"),
	preload("res://maps/river_crossing/river_crossing.tscn"),
	preload("res://maps/highlands/highlands.tscn"),
]
const LEVEL_INFO := [
	["GRASSLAND", "EASY"],
	["RIVER CROSSING", "MEDIUM"],
	["HIGHLANDS", "HARD"],
]
const GAME := preload("res://game/game.tscn")

const TITLE_IMG := preload("res://ui/mockups/title.webp")
const MENU_IMG := preload("res://ui/mockups/main_menu.webp")
const LEVELS_IMG := preload("res://ui/mockups/select_level.webp")
const SHOP_IMG := preload("res://ui/mockups/buy_guns.webp")

# Where the buttons are painted in each mockup.
const MENU_PLAY := Rect2(300, 259, 422, 83)
const MENU_SHOP := Rect2(345, 355, 335, 77)
const MENU_CONTROLS := Rect2(367, 450, 293, 72)
const TILE_X := [314, 420, 527, 634]
const TILE_Y := [157, 252, 347]
const TILE_SIZE := Vector2(76, 74)
const LEVELS_BACK := Rect2(412, 462, 198, 68)
const SHOP_BUY := [Rect2(290, 380, 97, 55), Rect2(462, 380, 98, 55), Rect2(635, 380, 97, 55)]
const SHOP_BACK := Rect2(412, 462, 198, 72)
const TITLE_LOGO := Vector2(500, 230)

@onready var ui: Control = $UI
@onready var back_button: Button = %Back

var active_game: Node2D
var screens := {}
var current := ""
var _focus_default := {}
var _flash: ColorRect
var _coins: CoinCounter
var _level_tiles: Array[PopButton] = []
var _level_info: Label
var _shop_buttons: Array[PopButton] = []
var _shop_info: Label
var _menu_buttons: Array[PopButton] = []
var _busy := false


func _ready() -> void:
	SaveData.ensure_loaded()
	Player.ensure_input_actions()
	PixelArt.install_hand_cursor()
	_build_title()
	_build_main_menu()
	_build_level_select()
	_build_shop()
	_build_controls()

	_coins = CoinCounter.new()
	_coins.position = Vector2(1152 - 196, 12)
	ui.add_child(_coins)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.size = Vector2(1152, 648)
	ui.add_child(_flash)

	_show("title")


# ---------------------------------------------------------------- screens

func _make_stage(screen_name: String, image: Texture2D) -> Control:
	var stage := Control.new()
	stage.name = screen_name.capitalize()
	stage.size = image.get_size()
	stage.scale = Vector2(1152, 648) / image.get_size()
	stage.mouse_filter = Control.MOUSE_FILTER_PASS
	var bg := TextureRect.new()
	bg.texture = image
	bg.size = image.get_size()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(bg)
	ui.add_child(stage)
	screens[screen_name] = stage
	return stage


func _add_button(stage: Control, image: Texture2D, rect: Rect2, on_press: Callable) -> PopButton:
	var b := PopButton.over(image, rect)
	b.pressed.connect(on_press)
	stage.add_child(b)
	return b


func _build_title() -> void:
	var stage := _make_stage("title", TITLE_IMG)
	stage.mouse_filter = Control.MOUSE_FILTER_STOP
	stage.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	stage.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			_title_to_menu())
	var prompt := PixelArt.label("CLICK ANYWHERE TO START", 20)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.position = Vector2(0, 512)
	prompt.size = Vector2(stage.size.x, 30)
	stage.add_child(prompt)
	var blink := prompt.create_tween().set_loops()
	blink.tween_property(prompt, "modulate:a", 0.15, 0.55)
	blink.tween_property(prompt, "modulate:a", 1.0, 0.55)


func _build_main_menu() -> void:
	var stage := _make_stage("main", MENU_IMG)
	_menu_buttons = [
		_add_button(stage, MENU_IMG, MENU_PLAY, _show.bind("levels")),
		_add_button(stage, MENU_IMG, MENU_SHOP, _show.bind("shop")),
		_add_button(stage, MENU_IMG, MENU_CONTROLS, _show.bind("controls")),
	]
	_focus_default["main"] = _menu_buttons[0]


func _build_level_select() -> void:
	var stage := _make_stage("levels", LEVELS_IMG)
	for row in TILE_Y.size():
		for col in TILE_X.size():
			var i := row * TILE_X.size() + col
			var tile := _add_button(stage, LEVELS_IMG, Rect2(Vector2(TILE_X[col], TILE_Y[row]), TILE_SIZE), _on_level_pressed.bind(i))
			tile.show_arrow = false
			tile.sparkle_count = 3
			tile.locked = i >= LEVELS.size()
			tile.focus_entered.connect(_show_level_info.bind(i))
			_level_tiles.append(tile)
	var back := _add_button(stage, LEVELS_IMG, LEVELS_BACK, _show.bind("main"))
	back.focus_entered.connect(func(): _level_info.text = "")

	_level_info = PixelArt.label("", 15)
	_level_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_info.position = Vector2(262, 428)
	_level_info.size = Vector2(500, 26)
	stage.add_child(_level_info)
	_focus_default["levels"] = _level_tiles[0]


func _build_shop() -> void:
	var stage := _make_stage("shop", SHOP_IMG)
	for i in Guns.ORDER.size():
		var b := _add_button(stage, SHOP_IMG, SHOP_BUY[i], _on_shop_pressed.bind(i))
		b.focus_entered.connect(_show_gun_info.bind(i))
		_shop_buttons.append(b)
	var back := _add_button(stage, SHOP_IMG, SHOP_BACK, _show.bind("main"))
	back.focus_entered.connect(func(): _shop_info.text = "")

	_shop_info = PixelArt.label("", 13)
	_shop_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_info.position = Vector2(222, 438)
	_shop_info.size = Vector2(580, 22)
	stage.add_child(_shop_info)
	_focus_default["shop"] = _shop_buttons[0]


func _build_controls() -> void:
	var stage := _make_stage("controls", MENU_IMG)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.1, 0.9)
	dim.size = stage.size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(dim)

	var panel := Panel.new()
	panel.position = Vector2(232, 96)
	panel.size = Vector2(560, 382)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("232331")
	style.border_color = Color("d9963c")
	style.set_border_width_all(6)
	style.expand_margin_left = 3
	style.expand_margin_right = 3
	style.expand_margin_top = 3
	style.expand_margin_bottom = 3
	style.shadow_color = PixelArt.INK
	style.shadow_size = 4
	style.anti_aliasing = false
	panel.add_theme_stylebox_override("panel", style)
	stage.add_child(panel)

	# The painted CONTROLS button doubles as the panel's title plate.
	var title_crop := AtlasTexture.new()
	title_crop.atlas = MENU_IMG
	title_crop.region = MENU_CONTROLS
	var title := TextureRect.new()
	title.texture = title_crop
	title.position = Vector2(512 - MENU_CONTROLS.size.x * 0.5, 60)
	title.size = MENU_CONTROLS.size
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(title)

	var rows := [
		["A / D", "WALK"],
		["MOUSE", "AIM THE GUN"],
		["LEFT CLICK", "SHOOT - THE KICK THROWS YOU BACK"],
		["LAND", "RELOAD YOUR SHOTS"],
		["R", "RESTART THE LEVEL"],
		["ESC", "BACK TO THE MENU"],
	]
	for i in rows.size():
		var key := PixelArt.label(rows[i][0], 17, PixelArt.GOLD)
		key.position = Vector2(262, 160 + i * 44)
		key.size = Vector2(150, 30)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stage.add_child(key)
		var action := PixelArt.label(rows[i][1], 14)
		action.position = Vector2(432, 162 + i * 44)
		action.size = Vector2(340, 30)
		stage.add_child(action)

	var back := _add_button(stage, LEVELS_IMG, LEVELS_BACK, _show.bind("main"))
	back.position = Vector2(412, 448)
	_focus_default["controls"] = back


# ---------------------------------------------------------------- flow

func _show(screen_name: String) -> void:
	for key in screens:
		screens[key].visible = key == screen_name
	current = screen_name
	_coins.visible = screen_name != "title"
	_coins.queue_redraw()
	if screen_name == "levels":
		_refresh_levels()
	elif screen_name == "shop":
		_refresh_shop()
	var stage: Control = screens[screen_name]
	stage.modulate.a = 0.0
	stage.create_tween().tween_property(stage, "modulate:a", 1.0, 0.15)
	if _focus_default.has(screen_name):
		_focus_default[screen_name].grab_focus.call_deferred()


## Title click: a bullet ricochets off the logo, white flash, menu bounces in.
func _title_to_menu() -> void:
	if _busy or current != "title":
		return
	_busy = true
	var stage: Control = screens["title"]
	var bullet := Sprite2D.new()
	bullet.texture = load(SpriteSheets.GUNS + "bullet.png")
	bullet.hframes = 2
	bullet.frame = 1
	bullet.scale = Vector2(4, 4)
	bullet.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var start := Vector2(-80, 470)
	bullet.position = start
	bullet.rotation = (TITLE_LOGO - start).angle()
	stage.add_child(bullet)

	var t := create_tween()
	t.tween_property(bullet, "position", TITLE_LOGO, 0.16)
	t.tween_callback(func():
		var spark := AnimatedSprite2D.new()
		spark.sprite_frames = SpriteSheets.impact()
		spark.scale = Vector2(4, 4)
		spark.position = TITLE_LOGO
		spark.rotation = PI
		spark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spark.animation_finished.connect(spark.queue_free)
		stage.add_child(spark)
		spark.play(&"play")
		bullet.rotation = (Vector2(1120, -120) - TITLE_LOGO).angle()
		# Zoom punch around the screen centre.
		var base := stage.scale
		var grow := Vector2(1152, 648) * 0.06
		var punch := stage.create_tween()
		punch.tween_property(stage, "scale", base * 1.06, 0.06)
		punch.parallel().tween_property(stage, "position", -grow * 0.5, 0.06)
		punch.tween_property(stage, "scale", base, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		punch.parallel().tween_property(stage, "position", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	t.tween_property(bullet, "position", Vector2(1120, -120), 0.24)
	t.parallel().tween_property(_flash, "color:a", 1.0, 0.2).set_delay(0.1)
	t.tween_callback(func():
		bullet.queue_free()
		_show("main")
		screens["main"].modulate.a = 1.0)
	t.tween_property(_flash, "color:a", 0.0, 0.4)
	t.tween_callback(func():
		for i in _menu_buttons.size():
			_menu_buttons[i].hop(i * 0.08)
		_busy = false)


func _unhandled_input(event: InputEvent) -> void:
	if active_game != null:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_return_to_menu()
		return
	if current == "title" and (event is InputEventKey and event.pressed and not event.echo):
		_title_to_menu()
	elif event.is_action_pressed("ui_cancel") and current in ["levels", "shop", "controls"]:
		get_viewport().set_input_as_handled()
		_show("main")


# ---------------------------------------------------------------- levels

func _refresh_levels() -> void:
	for i in _level_tiles.size():
		_level_tiles[i].badge_check = SaveData.cleared.has(i)
		_level_tiles[i].queue_redraw()


func _show_level_info(i: int) -> void:
	if i < LEVEL_INFO.size():
		var done := "   ·   CLEARED" if SaveData.cleared.has(i) else ""
		_level_info.text = "%d  ·  %s  ·  %s%s" % [i + 1, LEVEL_INFO[i][0], LEVEL_INFO[i][1], done]
	else:
		_level_info.text = "LEVEL %d  ·  COMING SOON" % (i + 1)


func _on_level_pressed(i: int) -> void:
	if i >= LEVELS.size():
		return
	_start_level(i)


func _start_level(i: int) -> void:
	active_game = GAME.instantiate()
	active_game.level_scene = LEVELS[i]
	active_game.level_index = i
	active_game.restart_requested.connect(_restart_level.bind(i))
	add_child(active_game)
	ui.hide()
	back_button.show()


func _return_to_menu() -> void:
	_remove_game()
	back_button.hide()
	ui.show()
	_show("levels")


func _restart_level(i: int) -> void:
	_remove_game()
	_start_level(i)


func _remove_game() -> void:
	if active_game == null:
		return
	remove_child(active_game)
	active_game.queue_free()
	active_game = null


# ---------------------------------------------------------------- shop

func _refresh_shop() -> void:
	for i in Guns.ORDER.size():
		var id: StringName = Guns.ORDER[i]
		var b := _shop_buttons[i]
		if not SaveData.owns(id):
			b.face = PopButton.Face.TEXTURE
		elif SaveData.equipped == id:
			b.face = PopButton.Face.EQUIPPED
		else:
			b.face = PopButton.Face.EQUIP
	_coins.queue_redraw()


func _show_gun_info(i: int) -> void:
	var gun := Guns.get_gun(Guns.ORDER[i])
	var kick := int(clampf(gun.recoil / 135.0, 1, 4))
	var pellets := "  ·  %d PELLETS" % gun.pellets if gun.pellets > 1 else ""
	_shop_info.text = "%s  ·  KICK %s%s  ·  %d SHOTS%s  ·  %d BOUNCES" % [
		gun.name.to_upper(), "|".repeat(kick), " ".repeat(4 - kick), gun.ammo, pellets, gun.bounces]


func _on_shop_pressed(i: int) -> void:
	var id: StringName = Guns.ORDER[i]
	var b := _shop_buttons[i]
	if SaveData.owns(id):
		SaveData.equip(id)
		b.hop()
	elif SaveData.buy(id):
		b.hop()
		_float_text(screens["shop"], "BOUGHT!", b.position + Vector2(b.size.x * 0.5, -8), Color("8ef07a"))
	else:
		b.shake()
		var need: int = Guns.get_gun(id).price - SaveData.coins
		_float_text(screens["shop"], "NEED %d MORE" % need, b.position + Vector2(b.size.x * 0.5, -8), Color("ff6b5a"))
	_refresh_shop()


func _float_text(stage: Control, text: String, at: Vector2, color: Color) -> void:
	var l := PixelArt.label(text, 15, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(200, 24)
	l.position = at - Vector2(100, 24)
	stage.add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "position:y", l.position.y - 26, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.3)
	t.tween_callback(l.queue_free)


## Coin wallet shown in the top-right corner of every menu screen.
class CoinCounter extends Control:
	func _init() -> void:
		size = Vector2(184, 44)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), PixelArt.INK)
		draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), Color("3b2a26"))
		draw_rect(Rect2(Vector2(3, 3), Vector2(size.x - 6, 3)), Color("6b4a3a"))
		PixelArt.draw_coin(self, Vector2(26, 22), 2.0)
		var text := str(SaveData.coins)
		draw_string_outline(PixelArt.FONT, Vector2(48, 31), text, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 60, 24, 6, PixelArt.INK)
		draw_string(PixelArt.FONT, Vector2(48, 31), text, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 60, 24, PixelArt.GOLD)
