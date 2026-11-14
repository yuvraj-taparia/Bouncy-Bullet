class_name SaveData
extends RefCounted
## Coins, owned guns, the equipped gun and cleared levels, saved to
## user://save.cfg so they survive closing the game.

const PATH := "user://save.cfg"
const COIN_VALUE := 10        ## each coin picked up in a level
const CLEAR_BONUS := 20       ## every time you reach the Safezone
const FIRST_CLEAR_BONUS := 30 ## extra the first time you clear a level

static var coins := 0
static var owned: Array[StringName] = [&"pistol"]
static var equipped: StringName = &"pistol"
static var cleared: Array[int] = []
static var _loaded := false


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	coins = cfg.get_value("player", "coins", 0)
	owned.clear()
	for id in cfg.get_value("player", "owned", ["pistol"]):
		owned.append(StringName(id))
	if not owned.has(&"pistol"):
		owned.append(&"pistol")
	equipped = StringName(cfg.get_value("player", "equipped", "pistol"))
	if not owned.has(equipped):
		equipped = &"pistol"
	cleared.clear()
	for i in cfg.get_value("player", "cleared", []):
		cleared.append(int(i))


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "coins", coins)
	cfg.set_value("player", "owned", owned.map(func(id): return String(id)))
	cfg.set_value("player", "equipped", String(equipped))
	cfg.set_value("player", "cleared", cleared)
	cfg.save(PATH)


static func owns(id: StringName) -> bool:
	ensure_loaded()
	return owned.has(id)


## Returns true when the gun was bought.
static func buy(id: StringName) -> bool:
	ensure_loaded()
	var price: int = Guns.get_gun(id).price
	if owned.has(id) or coins < price:
		return false
	coins -= price
	owned.append(id)
	equipped = id
	save()
	return true


static func equip(id: StringName) -> void:
	ensure_loaded()
	if owned.has(id):
		equipped = id
		save()


## Pays out a finished level and returns how many coins were earned.
static func finish_level(level_index: int, coins_picked_up: int) -> int:
	ensure_loaded()
	var earned := coins_picked_up * COIN_VALUE + CLEAR_BONUS
	if not cleared.has(level_index):
		cleared.append(level_index)
		earned += FIRST_CLEAR_BONUS
	coins += earned
	save()
	return earned
