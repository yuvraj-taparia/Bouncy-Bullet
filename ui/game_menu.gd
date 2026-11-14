extends Node

const LEVELS := [
	["Wiesenland", "Wiesenpfad", "Leicht", preload("res://maps/campaign/meadow_path.tscn")],
	["Wiesenland", "Hangwiese", "Mittel", preload("res://maps/campaign/hillside.tscn")],
	["Wiesenland", "Nashornpass", "Schwer", preload("res://maps/campaign/rhino_pass.tscn")],
	["Flussland", "Sandbank", "Leicht", preload("res://maps/campaign/sandbank.tscn")],
	["Flussland", "Biberdamm", "Mittel", preload("res://maps/campaign/beaver_dam.tscn")],
	["Flussland", "Stromschnellen", "Schwer", preload("res://maps/campaign/rapids.tscn")],
	["Tiefenhöhle", "Grotte", "Leicht", preload("res://maps/campaign/grotto.tscn")],
	["Tiefenhöhle", "Wurmtunnel", "Mittel", preload("res://maps/campaign/worm_tunnel.tscn")],
	["Tiefenhöhle", "Tiefenschacht", "Schwer", preload("res://maps/campaign/deep_shaft.tscn")],
	["Dschungelruinen", "Tempelgarten", "Leicht", preload("res://maps/campaign/temple_garden.tscn")],
	["Dschungelruinen", "Rankenhallen", "Mittel", preload("res://maps/campaign/vine_halls.tscn")],
	["Dschungelruinen", "Kronendach", "Schwer", preload("res://maps/campaign/canopy.tscn")],
]
const GAME := preload("res://game/game.tscn")
const COIN_WALLET := preload("res://game/coin_wallet.gd")

@onready var menu: Control = $Menu
@onready var level_list: VBoxContainer = %Levels
@onready var play_button: Button = %Play
@onready var back_button: Button = %Back
@onready var preview_viewport: SubViewport = %Viewport
@onready var preview_camera: Camera2D = %Viewport/Camera2D
@onready var coin_balance: Label = %CoinBalance

var level_buttons := ButtonGroup.new()
var active_game: Node2D
var preview_level: Node2D


func _ready() -> void:
	for index in LEVELS.size():
		var level := LEVELS[index] as Array
		var button := Button.new()
		button.text = "%02d  %s  ·  %s\n     %s" % [index + 1, level[1], level[2], level[0]]
		button.add_theme_font_size_override("font_size", 16)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 56
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.toggle_mode = true
		button.button_group = level_buttons
		level_list.add_child(button)
		button.focus_entered.connect(_select_focused_level.bind(button))
		if index == 0:
			button.button_pressed = true
	level_buttons.pressed.connect(_show_preview)
	_show_preview(level_buttons.get_pressed_button())
	_update_coin_balance()
	play_button.grab_focus()


func _select_focused_level(button: Button) -> void:
	if not button.button_pressed:
		button.button_pressed = true
		_show_preview(button)


func _show_preview(selected: BaseButton) -> void:
	var scene: PackedScene = LEVELS[selected.get_index()][3]
	if preview_level != null and preview_level.scene_file_path == scene.resource_path:
		return
	if preview_level != null:
		preview_viewport.remove_child(preview_level)
		preview_level.queue_free()
	preview_level = scene.instantiate()
	preview_level.process_mode = Node.PROCESS_MODE_DISABLED
	preview_viewport.add_child(preview_level)
	var terrain: TileMapLayer = preview_level.get_node("Terrain")
	var tile_width := terrain.tile_set.tile_size.x
	var bounds := terrain.get_used_rect()
	var width := float(bounds.size.x * tile_width)
	preview_camera.position.x = (bounds.position.x + bounds.size.x * 0.5) * tile_width
	preview_camera.zoom = Vector2.ONE * minf(0.9, preview_viewport.size.x / (width + 64.0))


func _unhandled_input(event: InputEvent) -> void:
	if active_game != null and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_menu()


func _start_level() -> void:
	var selected := level_buttons.get_pressed_button()
	active_game = GAME.instantiate()
	active_game.level_scene = LEVELS[selected.get_index()][3]
	active_game.restart_requested.connect(_restart_level)
	add_child(active_game)
	menu.hide()
	back_button.show()


func _return_to_menu() -> void:
	_remove_game()
	back_button.hide()
	_update_coin_balance()
	menu.show()
	play_button.grab_focus()


func _restart_level() -> void:
	_remove_game()
	_start_level()


func _remove_game() -> void:
	remove_child(active_game)
	active_game.queue_free()
	active_game = null


func _update_coin_balance() -> void:
	var balance := COIN_WALLET.balance()
	coin_balance.text = "Guthaben: %d Coins" % balance if balance >= 0 else "Guthaben nicht lesbar"
