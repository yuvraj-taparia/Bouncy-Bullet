extends SceneTree

# Use an override.cfg with a dedicated application/config/custom_user_dir_name
# beginning with "bouncy-bullet-test-". Run with --script in the order
# -- fresh, -- seed, -- migrate, -- restart. Between seed and migrate, run
# -- failed-write under an OS file-size limit below the serialized save size.
const MAP := "res://maps/campaign/meadow_path.tscn"


func _initialize() -> void:
	if not OS.get_user_data_dir().get_file().begins_with("bouncy-bullet-test-"):
		push_error("Use a dedicated bouncy-bullet-test-* save directory")
		quit(1)
		return

	var args := OS.get_cmdline_user_args()
	var phase := args[0] if args.size() == 1 else ""
	var failure: String
	match phase:
		"fresh":
			failure = _check_fresh()
		"seed":
			failure = _seed()
		"failed-write":
			failure = _check_failed_write()
		"migrate":
			failure = _check_migration()
		"restart":
			failure = _check_restart()
		_:
			failure = "Select a save check phase"

	if failure.is_empty():
		print("Save check passed: ", phase)
		quit()
	else:
		push_error("%s: %s" % [phase, failure])
		quit(1)


func _check_fresh() -> String:
	if FileAccess.file_exists(SaveData.PATH) or FileAccess.file_exists(SaveData.LEGACY_WALLET):
		return "Expected a fresh test profile"
	SaveData.ensure_loaded()
	if SaveData.coins != 0 or SaveData.owned != [&"glock"]:
		return "Expected no coins and the starter Glock"
	if SaveData.finish_level(MAP, 0) != 50:
		return "Expected the first-clear reward"
	if not SaveData.buy(&"pistol") or SaveData.coins != 0:
		return "Expected a pistol purchase for 50 coins"
	return ""


func _seed() -> String:
	var previous := ConfigFile.new()
	previous.set_value("player", "coins", 120)
	previous.set_value("player", "owned", ["glock", "pistol"])
	previous.set_value("player", "equipped", "pistol")
	previous.set_value("player", "cleared", [0, 2])
	if previous.save(SaveData.PATH) != OK:
		return "Could not seed the v2 save"
	var wallet := ConfigFile.new()
	wallet.set_value("wallet", "coins", 45)
	if wallet.save(SaveData.LEGACY_WALLET) != OK:
		return "Could not seed the legacy wallet"
	return ""


func _check_failed_write() -> String:
	var before := FileAccess.get_file_as_bytes(SaveData.PATH)
	var wallet_before := FileAccess.get_file_as_bytes(SaveData.LEGACY_WALLET)
	if before.is_empty() or wallet_before.is_empty():
		return "Seed both save files before testing a failed write"

	SaveData.ensure_loaded()
	if SaveData.coins != 120 or SaveData.equipped != &"pistol":
		return "Failed migration changed the in-memory balance or weapon"
	if SaveData.finish_level(MAP, 1) != -1 or SaveData.coins != 120 or not SaveData.cleared.is_empty():
		return "Failed reward changed the in-memory balance or progress"
	if FileAccess.get_file_as_bytes(SaveData.PATH) != before:
		return "Failed write replaced the existing save"
	if FileAccess.get_file_as_bytes(SaveData.LEGACY_WALLET) != wallet_before:
		return "Failed write changed the legacy wallet"
	return ""


func _check_migration() -> String:
	SaveData.ensure_loaded()
	if SaveData.coins != 165 or SaveData.equipped != &"pistol" or not SaveData.owns(&"pistol"):
		return "Expected the combined balance, inventory and equipped pistol"
	if not SaveData.cleared.is_empty():
		return "Legacy level numbers must not mark campaign maps cleared"
	if SaveData.finish_level(MAP, 1) != 60 or SaveData.finish_level(MAP, 1) != 30:
		return "Expected the first-clear bonus exactly once"
	if not SaveData.buy(&"shotgun") or SaveData.coins != 105:
		return "Expected a shotgun purchase for 150 coins"
	return ""


func _check_restart() -> String:
	SaveData.ensure_loaded()
	if SaveData.coins != 105 or SaveData.equipped != &"shotgun":
		return "Restart changed the balance or equipped weapon"
	if not SaveData.owns(&"pistol") or not SaveData.owns(&"shotgun") or SaveData.cleared != [MAP]:
		return "Restart lost gun ownership or campaign progress"
	var cfg := ConfigFile.new()
	if cfg.load(SaveData.PATH) != OK:
		return "Could not read the saved progress"
	if cfg.get_value("player", "cleared", []) != [0, 2]:
		return "Restart lost the old level clears"
	if not cfg.get_value("player", "legacy_wallet_imported", false):
		return "The wallet import marker was not saved"
	return ""
