extends Node

const LEVELS: Array[PackedScene] = [
	preload("res://maps/grassland/grassland.tscn"),
	preload("res://maps/river_crossing/river_crossing.tscn"),
	preload("res://maps/highlands/highlands.tscn"),
]
const SCROLL_CAMERA := preload("res://maps/scroll_camera.tscn")

@onready var menu: Control = $Menu
@onready var level_buttons: ButtonGroup = %Grassland.button_group
@onready var play_button: Button = %Play
@onready var back_button: Button = %Back
@onready var preview_viewport: SubViewport = %Viewport

var active_level: Node2D
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


func _unhandled_input(event: InputEvent) -> void:
	if active_level != null and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_menu()


func _start_level() -> void:
	var selected := level_buttons.get_pressed_button()
	active_level = LEVELS[selected.get_index()].instantiate()
	active_level.add_child(SCROLL_CAMERA.instantiate())
	add_child(active_level)
	menu.hide()
	back_button.show()
	back_button.grab_focus()


func _return_to_menu() -> void:
	active_level.queue_free()
	active_level = null
	back_button.hide()
	menu.show()
	play_button.grab_focus()
