extends Node

const LEVELS: Array[PackedScene] = [
	preload("res://maps/grassland/grassland.tscn"),
	preload("res://maps/river_crossing/river_crossing.tscn"),
	preload("res://maps/highlands/highlands.tscn"),
]
const GAME := preload("res://game/game.tscn")

@onready var menu: Control = $Menu
@onready var level_buttons: ButtonGroup = %Grassland.button_group
@onready var play_button: Button = %Play
@onready var back_button: Button = %Back
@onready var preview_viewport: SubViewport = %Viewport
@onready var preview_camera: Camera2D = %Viewport/Camera2D
var active_game: Node2D
var preview_level: Node2D


func _ready() -> void:
	level_buttons.pressed.connect(_show_preview)
	_show_preview(level_buttons.get_pressed_button())
	play_button.grab_focus()


func _show_preview(selected: BaseButton) -> void:
	if preview_level != null:
		preview_viewport.remove_child(preview_level)
		preview_level.queue_free()
	preview_level = LEVELS[selected.get_index()].instantiate()
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
	active_game.level_scene = LEVELS[selected.get_index()]
	active_game.restart_requested.connect(_restart_level)
	add_child(active_game)
	menu.hide()
	back_button.show()


func _return_to_menu() -> void:
	_remove_game()
	back_button.hide()
	menu.show()
	play_button.grab_focus()


func _restart_level() -> void:
	_remove_game()
	_start_level()


func _remove_game() -> void:
	remove_child(active_game)
	active_game.queue_free()
	active_game = null
