extends SceneTree

# Use an override.cfg with a dedicated application/config/custom_user_dir_name
# beginning with "bouncy-bullet-test-". Run with --script in the order
# -- fresh, -- seed, -- migrate, -- restart.
const MAP := "res://maps/campaign/meadow_path.tscn"


func _initialize() -> void:
	if not OS.get_user_data_dir().get_file().begins_with("bouncy-bullet-test-"):
		push_error("Use a dedicated bouncy-bullet-test-* save directory")
		quit(1)
		return
	var args := Array(OS.get_cmdline_user_args())
	if args == ["seed"]:
		var previous := ConfigFile.new()
		previous.set_value("player", "coins", 120)
		previous.set_value("player", "owned", ["glock", "pistol"])
		previous.set_value("player", "equipped", "pistol")
		previous.set_value("player", "cleared", [0, 2])
		assert(previous.save(SaveData.PATH) == OK)
		var wallet := ConfigFile.new()
		wallet.set_value("wallet", "coins", 45)
		assert(wallet.save(SaveData.LEGACY_WALLET) == OK)
	elif args == ["migrate"]:
		SaveData.ensure_loaded()
		assert(SaveData.coins == 165 and SaveData.equipped == &"pistol")
		assert(SaveData.owns(&"pistol") and SaveData.cleared.is_empty())
		assert(SaveData.finish_level(MAP, 1) == 60)
		assert(SaveData.finish_level(MAP, 1) == 30)
		assert(SaveData.buy(&"shotgun") and SaveData.coins == 105)
	elif args == ["restart"]:
		SaveData.ensure_loaded()
		assert(SaveData.coins == 105 and SaveData.equipped == &"shotgun")
		assert(SaveData.owns(&"pistol") and SaveData.owns(&"shotgun"))
		assert(SaveData.cleared == [MAP])
		var cfg := ConfigFile.new()
		assert(cfg.load(SaveData.PATH) == OK)
		assert(cfg.get_value("player", "cleared") == [0, 2])
		assert(cfg.get_value("player", "legacy_wallet_imported"))
	else:
		assert(args == ["fresh"])
		assert(not FileAccess.file_exists(SaveData.PATH))
		assert(not FileAccess.file_exists(SaveData.LEGACY_WALLET))
		SaveData.ensure_loaded()
		assert(SaveData.coins == 0 and SaveData.owned == [&"glock"])
		assert(SaveData.finish_level(MAP, 0) == 50)
		assert(SaveData.buy(&"pistol") and SaveData.coins == 0)
	print("Save check passed: ", args[0])
	quit()
