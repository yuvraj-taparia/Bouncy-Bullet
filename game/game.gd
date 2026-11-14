extends Node2D
## Runs one level: spawns the player, handles falling in the water, reaching
## the Safezone, the run timer and restarting.

signal restart_requested

@export var level_scene: PackedScene

var level: Node2D
@onready var player: Player = $Player
@onready var hud = $HUD
@onready var _respawn_timer: Timer = $RespawnTimer

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
	var terrain: TileMapLayer = level.get_node("Terrain")
	player.camera.limit_right = terrain.get_used_rect().end.x * terrain.tile_set.tile_size.x + 76
	player.camera.reset_smoothing()
	player.ammo_changed.connect(hud.set_ammo)
	player.fired.connect(func(): _shots += 1)
	hud.set_ammo(player.ammo, player.max_ammo)
	level.get_node("Safezone").body_entered.connect(_on_safezone_entered)
	level.get_node("FallZone").body_entered.connect(_on_fall_zone_entered)
	for group_name in ["Mobs", "Hazards"]:
		var group := level.get_node_or_null(group_name)
		if group != null:
			for obstacle in group.get_children():
				obstacle.player_touched.connect(_on_obstacle_touched)
	var coins := level.get_node("Coins").get_children()
	_coins_total = coins.size()
	for coin in coins:
		coin.collected.connect(_on_coin_collected)
	hud.set_coins(_coins_collected, _coins_total)


func _process(delta: float) -> void:
	if not _won:
		_time += delta
	hud.set_time(_time)
	if not _respawn_timer.is_stopped():
		hud.set_respawn_countdown(ceili(_respawn_timer.time_left))


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


func _on_obstacle_touched(body: Node2D) -> void:
	if body == player:
		_start_respawn()


func _on_fall_zone_entered(body: Node2D) -> void:
	if body == player and _start_respawn():
		_splashes += 1


func _start_respawn() -> bool:
	if _won or not _respawn_timer.is_stopped():
		return false
	# Move the player and disable its collision outside the physics callback.
	player.prepare_respawn.call_deferred(_spawn_point())
	_respawn_timer.start()
	hud.set_respawn_countdown(ceili(_respawn_timer.wait_time))
	return true


func _on_respawn_timer_timeout() -> void:
	player.finish_respawn()
	hud.set_respawn_countdown(0)


func _on_safezone_entered(body: Node2D) -> void:
	if body != player or _won or not _respawn_timer.is_stopped():
		return
	_won = true
	player.frozen = true
	_finish_run.call_deferred()


func _finish_run() -> void:
	var earned := SaveData.finish_level(level_scene.resource_path, _coins_collected)
	hud.show_win(_time, _shots, _splashes, earned, SaveData.coins)
