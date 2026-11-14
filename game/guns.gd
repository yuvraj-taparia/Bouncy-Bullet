class_name Guns
extends RefCounted
## Every gun in the game and how it feels to shoot. The shop and the player
## both read from this table.
##
## Gameplay
##   recoil      how hard each shot throws you (pixels/second)
##   ammo        shots before you have to land
##   cooldown    seconds between shots
##   pellets     bullets per shot (spread over `spread` radians)
##   bounces     how many times each bullet ricochets
##   lifetime    seconds a bullet lives
##   reload_time seconds the (sped-up) reload animation takes after landing
##
## Looks: the animated gun scene from the gun pack template, which
## attachments to show, the magazine that drops out on reload, the casing
## sprite, and how fast to play its animations.

const TEMPLATE := "res://assets/gun_template/"
const SPRITES := "res://assets/pixel_art_guns/sprites/"

## Guns sold on the three painted shop cards, in card order.
const ORDER: Array[StringName] = [&"pistol", &"shotgun", &"bounce_rifle"]
## Every gun, including ones not on a shop card yet.
const ALL: Array[StringName] = [&"pistol", &"shotgun", &"bounce_rifle", &"glock"]

const DATA := {
	&"pistol": {
		"name": "Pistol", "price": 50,
		"recoil": 360.0, "ammo": 3, "cooldown": 0.22,
		"pellets": 1, "spread": 0.0, "bounces": 3, "lifetime": 1.6,
		"reload_time": 0.6, "bullet_color": Color(1, 1, 1),
		"scene": TEMPLATE + "guns/deserteagle.tscn",
		"attachments": {
			"Sight": TEMPLATE + "attachments/sights/DesertEagleSight.tscn",
			"Muzzle": TEMPLATE + "attachments/muzzles/GlockMuzzle.tscn",
		},
		"mag": TEMPLATE + "attachments/mags/GlockMag.tscn",
		"casing": SPRITES + "particles/casings/PistolCasing.png",
		"handling": {"rot": Vector2(0.6, 2.0), "x": Vector2(0.8, 1.4), "y": Vector2(0.8, 1.4)},
		"pickup_speed": 3.0, "shoot_speed": 1.3, "recoil_speed": 1.6,
	},
	&"shotgun": {
		"name": "Shotgun", "price": 150,
		"recoil": 540.0, "ammo": 2, "cooldown": 0.45,
		"pellets": 5, "spread": 0.5, "bounces": 1, "lifetime": 0.45,
		"reload_time": 0.9, "bullet_color": Color(1, 0.8, 0.55),
		"scene": TEMPLATE + "guns/m3.tscn",
		"attachments": {},
		"mag": "",
		"casing": SPRITES + "particles/casings/ShotgunCasing.png",
		"handling": {"rot": Vector2(0.8, 1.5), "x": Vector2(0.8, 1.4), "y": Vector2(0.8, 1.3)},
		"pickup_speed": 3.0, "shoot_speed": 2.5, "recoil_speed": 2.0,
	},
	&"bounce_rifle": {
		"name": "Bounce Rifle", "price": 300,
		"recoil": 190.0, "ammo": 6, "cooldown": 0.09,
		"pellets": 1, "spread": 0.06, "bounces": 6, "lifetime": 2.6,
		"reload_time": 0.7, "bullet_color": Color(0.55, 1, 0.45),
		"scene": TEMPLATE + "guns/ak47.tscn",
		"attachments": {
			"Stock": TEMPLATE + "attachments/stocks/AK47NormalStock.tscn",
			"Sight": TEMPLATE + "attachments/sights/RedDot.tscn",
			"Grip": TEMPLATE + "attachments/grips/AK47ForeGrip.tscn",
		},
		"mag": TEMPLATE + "attachments/mags/AK47NormalMag.tscn",
		"casing": SPRITES + "particles/casings/AK47Casing.png",
		"handling": {"rot": Vector2(0.8, 2.4), "x": Vector2(0.7, 1.2), "y": Vector2(0.7, 1.2)},
		"pickup_speed": 3.0, "shoot_speed": 1.5, "recoil_speed": 2.5,
	},
	&"glock": {
		"name": "Glock", "price": 100,
		"recoil": 260.0, "ammo": 5, "cooldown": 0.12,
		"pellets": 1, "spread": 0.04, "bounces": 2, "lifetime": 1.4,
		"reload_time": 0.5, "bullet_color": Color(1, 0.95, 0.8),
		"scene": TEMPLATE + "guns/glock.tscn",
		"attachments": {
			"Sight": TEMPLATE + "attachments/sights/GlockSight.tscn",
			"Muzzle": TEMPLATE + "attachments/muzzles/GlockMuzzle.tscn",
		},
		"mag": TEMPLATE + "attachments/mags/GlockMag.tscn",
		"casing": SPRITES + "particles/casings/PistolCasing.png",
		"handling": {"rot": Vector2(0.8, 1.5), "x": Vector2(0.8, 1.3), "y": Vector2(0.8, 1.3)},
		"pickup_speed": 3.0, "shoot_speed": 1.3, "recoil_speed": 2.0,
	},
}


static func get_gun(id: StringName) -> Dictionary:
	return DATA.get(id, DATA[&"pistol"])
