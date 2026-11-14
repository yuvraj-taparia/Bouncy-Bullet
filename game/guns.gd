class_name Guns
extends RefCounted
## Every gun the player can buy, and how it feels to shoot.
## Tweak numbers here; the shop and the player both read from this table.
##
##   recoil     how hard each shot throws you (pixels/second)
##   ammo       shots before you have to land
##   cooldown   seconds between shots
##   pellets    bullets per shot (shotgun spreads them over `spread` radians)
##   bounces    how many times each bullet ricochets
##   lifetime   seconds a bullet lives
##   grip       sprite offset that puts the grip on the player's hand
##   muzzle     where bullets leave the barrel, relative to the hand

const ORDER: Array[StringName] = [&"pistol", &"shotgun", &"bounce_rifle"]

const DATA := {
	&"pistol": {
		"name": "Pistol", "price": 50,
		"recoil": 360.0, "ammo": 3, "cooldown": 0.22,
		"pellets": 1, "spread": 0.0, "bounces": 3, "lifetime": 1.6,
		"bullet_color": Color(1, 1, 1),
		"idle": "guns/deserteagle/deserteagle.png",
		"shoot": "guns/deserteagle/deserteagle-shoot.png", "shoot_frames": 9, "shoot_fps": 30.0,
		"reload": "guns/deserteagle/deserteagle-reload.png", "reload_frames": 3,
		"grip": Vector2(7, -3), "muzzle": Vector2(21, -9),
	},
	&"shotgun": {
		"name": "Shotgun", "price": 150,
		"recoil": 540.0, "ammo": 2, "cooldown": 0.45,
		"pellets": 5, "spread": 0.5, "bounces": 1, "lifetime": 0.45,
		"bullet_color": Color(1, 0.8, 0.55),
		"idle": "guns/m3/m3.png",
		"shoot": "guns/m3/m3-shoot.png", "shoot_frames": 17, "shoot_fps": 40.0,
		"reload": "", "reload_frames": 0,
		"grip": Vector2(17, -6), "muzzle": Vector2(47, -10),
	},
	&"bounce_rifle": {
		"name": "Bounce Rifle", "price": 300,
		"recoil": 190.0, "ammo": 6, "cooldown": 0.09,
		"pellets": 1, "spread": 0.06, "bounces": 6, "lifetime": 2.6,
		"bullet_color": Color(0.55, 1, 0.45),
		"idle": "guns/ak47/ak47.png",
		"shoot": "guns/ak47/ak-shoot.png", "shoot_frames": 7, "shoot_fps": 45.0,
		"reload": "", "reload_frames": 0,
		"grip": Vector2(11, -7), "muzzle": Vector2(35, -11),
	},
}

static var _frames := {}


static func get_gun(id: StringName) -> Dictionary:
	return DATA.get(id, DATA[&"pistol"])


## SpriteFrames with "idle", "shoot" and (when the pack has one) "reload".
static func frames(id: StringName) -> SpriteFrames:
	if _frames.has(id):
		return _frames[id]
	var gun := get_gun(id)
	var sf := SpriteFrames.new()
	sf.remove_animation(&"default")
	SpriteSheets.add_strip(sf, &"idle", SpriteSheets.GUNS + gun.idle, 1, 1.0, true)
	SpriteSheets.add_strip(sf, &"shoot", SpriteSheets.GUNS + gun.shoot, gun.shoot_frames, gun.shoot_fps)
	if gun.reload != "":
		SpriteSheets.add_strip(sf, &"reload", SpriteSheets.GUNS + gun.reload, gun.reload_frames, 10.0)
	_frames[id] = sf
	return sf
