extends Node2D
## Runs one level: spawns the player, handles falling in the water, reaching
## the Safezone, the run timer and restarting.

signal restart_requested

@export var level_scene: PackedScene

var level: Node2D
@onready var player: Player = $Player
@onready var hud = $HUD

var _time := 0.0
var _shots := 0
var _splashes := 0
var _won := false
var _coins_collected := 0
var _coins_total := 0


func _ready() -> void:
	level = level_scene.instantiate()
	add_child(level)
	move_child(level, 0)
	player.global_position = _spawn_point()
	player.camera.reset_smoothing()
	player.ammo_changed.connect(hud.set_ammo)
	player.fired.connect(func(): _shots += 1)
	hud.set_ammo(player.ammo, Player.MAX_AMMO)
	level.get_node("Safezone").body_entered.connect(_on_safezone_entered)
	level.get_node("FallZone").body_entered.connect(_on_fall_zone_entered)
	var coins := level.get_node("Coins").get_children()
	_coins_total = coins.size()
	for coin in coins:
		coin.collected.connect(_on_coin_collected)
	hud.set_coins(_coins_collected, _coins_total)


func _process(delta: float) -> void:
	if not _won:
		_time += delta
	hud.set_time(_time)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"restart"):
		get_viewport().set_input_as_handled()
		if get_tree().current_scene == self:
			get_tree().reload_current_scene()
		else:
			restart_requested.emit()


func _on_coin_collected() -> void:
	_coins_collected += 1
	hud.set_coins(_coins_collected, _coins_total)


func _spawn_point() -> Vector2:
	return level.get_node("PlayerSpawn").global_position


func _on_fall_zone_entered(body: Node2D) -> void:
	if body != player or _won:
		return
	_splashes += 1
	# Respawn on the next physics frame; moving a body inside its own
	# collision callback is unreliable.
	player.respawn.call_deferred(_spawn_point())


func _on_safezone_entered(body: Node2D) -> void:
	if body != player or _won:
		return
	_won = true
	player.frozen = true
	hud.show_win(_time, _shots, _splashes)
