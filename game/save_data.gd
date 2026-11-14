class_name SaveData
extends RefCounted
## Shared balance, gun inventory and campaign progress.

const PATH := "user://save.cfg"
const LEGACY_WALLET := "user://coins.cfg"
const MAX_COINS := 9223372036854775807
const COIN_VALUE := 10
const CLEAR_BONUS := 20
const FIRST_CLEAR_BONUS := 30
const STARTER: StringName = &"glock"

static var coins := 0
static var owned: Array[StringName] = [STARTER]
static var equipped: StringName = STARTER
static var cleared: Array[String] = []
static var _loaded := false
static var _read_error := OK
static var _wallet_imported := false
static var _config := ConfigFile.new()


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_read_error = _config.load(PATH)
	if _read_error == ERR_FILE_NOT_FOUND:
		_read_error = OK
	elif _read_error != OK:
		push_warning("Could not read the existing save: %s" % error_string(_read_error))
		return

	var balance: Variant = _config.get_value("player", "coins", 0)
	if balance is int and balance >= 0:
		coins = balance
	else:
		_read_error = ERR_INVALID_DATA
		push_warning("Invalid coin balance in the existing save")
	var saved_owned: Variant = _config.get_value("player", "owned", [])
	if saved_owned is Array:
		for id in saved_owned:
			if (id is String or id is StringName) and Guns.DATA.has(StringName(id)):
				if not owned.has(StringName(id)):
					owned.append(StringName(id))
	var saved_equipped: Variant = _config.get_value("player", "equipped", String(STARTER))
	if (saved_equipped is String or saved_equipped is StringName) and owned.has(StringName(saved_equipped)):
		equipped = StringName(saved_equipped)
	var saved_cleared: Variant = _config.get_value("player", "cleared_campaign", [])
	if saved_cleared is Array:
		for level_id in saved_cleared:
			if level_id is String:
				cleared.append(level_id)
	_wallet_imported = _config.get_value("player", "legacy_wallet_imported", false) == true
	if not _wallet_imported and _read_error == OK:
		_import_wallet()


static func _import_wallet() -> void:
	var wallet := ConfigFile.new()
	var error := wallet.load(LEGACY_WALLET)
	if error == ERR_FILE_NOT_FOUND:
		return
	if error != OK:
		push_warning("Could not read the legacy coin balance: %s" % error_string(error))
		return
	var amount: Variant = wallet.get_value("wallet", "coins", 0)
	if not amount is int or amount < 0 or amount > MAX_COINS - coins:
		push_warning("Invalid legacy coin balance")
		return
	coins += amount
	_wallet_imported = true
	if _save() != OK:
		coins -= amount
		_wallet_imported = false


static func _save() -> Error:
	if _read_error != OK:
		return _read_error
	_config.set_value("player", "coins", coins)
	_config.set_value("player", "owned", owned.map(func(id): return String(id)))
	_config.set_value("player", "equipped", String(equipped))
	_config.set_value("player", "cleared_campaign", cleared)
	_config.set_value("player", "legacy_wallet_imported", _wallet_imported)
	var temp_path := PATH + ".tmp"
	var error := _write_save(temp_path)
	if error == OK:
		error = DirAccess.rename_absolute(temp_path, PATH)
	if error != OK:
		push_warning("Could not save game progress: %s" % error_string(error))
	return error


static func _write_save(path: String) -> Error:
	var error := _config.save(path)
	if error != OK:
		return error
	# ConfigFile.save() can report success after a short write.
	var written := ConfigFile.new()
	if written.load(path) != OK or written.get_sections() != _config.get_sections():
		return ERR_FILE_CANT_WRITE
	if written.encode_to_text() != _config.encode_to_text():
		return ERR_FILE_CANT_WRITE
	return OK


static func owns(id: StringName) -> bool:
	ensure_loaded()
	return owned.has(id)


static func buy(id: StringName) -> bool:
	ensure_loaded()
	if not Guns.DATA.has(id) or owned.has(id):
		return false
	var price: int = Guns.get_gun(id).price
	if coins < price:
		return false

	var previous := equipped
	coins -= price
	owned.append(id)
	equipped = id
	if _save() == OK:
		return true
	equipped = previous
	owned.pop_back()
	coins += price
	return false


static func equip(id: StringName) -> bool:
	ensure_loaded()
	if not owned.has(id):
		return false
	var previous := equipped
	equipped = id
	if _save() == OK:
		return true
	equipped = previous
	return false


## Returns the reward, or -1 when the finished run could not be saved.
static func finish_level(level_id: String, coins_picked_up: int) -> int:
	ensure_loaded()
	var first_clear := not cleared.has(level_id)
	var earned := coins_picked_up * COIN_VALUE + CLEAR_BONUS
	if first_clear:
		earned += FIRST_CLEAR_BONUS
	if earned > MAX_COINS - coins:
		return -1

	coins += earned
	if first_clear:
		cleared.append(level_id)
	if _save() == OK:
		return earned
	if first_clear:
		cleared.pop_back()
	coins -= earned
	return -1
