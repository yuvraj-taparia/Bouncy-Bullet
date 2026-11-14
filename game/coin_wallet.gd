extends RefCounted

const SAVE_PATH := "user://coins.cfg"


static func balance() -> int:
	var save := ConfigFile.new()
	var error := save.load(SAVE_PATH)
	if error == ERR_FILE_NOT_FOUND:
		return 0
	if error != OK:
		return -1
	var value: Variant = save.get_value("wallet", "coins", 0)
	return value if value is int and value >= 0 else -1


static func deposit(amount: int) -> Error:
	var current := balance()
	if current < 0 or amount < 0 or amount > 9223372036854775807 - current:
		return ERR_INVALID_DATA
	var save := ConfigFile.new()
	save.set_value("wallet", "coins", current + amount)
	var temp_path := SAVE_PATH + ".tmp"
	var error := save.save(temp_path)
	if error != OK:
		return error
	return DirAccess.rename_absolute(temp_path, SAVE_PATH)
