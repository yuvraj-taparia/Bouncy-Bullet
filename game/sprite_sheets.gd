class_name SpriteSheets
extends RefCounted
## Builds SpriteFrames from the horizontal sprite strips in the pixel art guns pack.

const GUNS := "res://assets/pixel_art_guns/sprites/"

static var _cache := {}


## Adds an animation called `anim` to `frames`, cut from a horizontal strip
## of `count` equal-width frames.
static func add_strip(frames: SpriteFrames, anim: StringName, path: String, count: int, fps: float, loop := false) -> void:
	var texture: Texture2D = load(path)
	var w := texture.get_width() / count
	var h := texture.get_height()
	if not frames.has_animation(anim):
		frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loop)
	for i in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * w, 0, w, h)
		frames.add_frame(anim, atlas)


## Desert Eagle: idle, shoot (9 frames) and reload (3 frames).
static func desert_eagle() -> SpriteFrames:
	if _cache.has("deagle"):
		return _cache["deagle"]
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	add_strip(frames, &"idle", GUNS + "guns/deserteagle/deserteagle.png", 1, 1.0, true)
	add_strip(frames, &"shoot", GUNS + "guns/deserteagle/deserteagle-shoot.png", 9, 30.0)
	add_strip(frames, &"reload", GUNS + "guns/deserteagle/deserteagle-reload.png", 3, 10.0)
	_cache["deagle"] = frames
	return frames


static func one_shot(key: String, path: String, count: int, fps: float) -> SpriteFrames:
	if _cache.has(key):
		return _cache[key]
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	add_strip(frames, &"play", path, count, fps)
	_cache[key] = frames
	return frames


static func muzzle_flash() -> SpriteFrames:
	return one_shot("muzzle", GUNS + "particles/muzzle.png", 4, 28.0)


static func impact() -> SpriteFrames:
	return one_shot("impact", GUNS + "particles/sImpactParticle_strip4.png", 4, 20.0)


## Plays a one-shot effect at a world position and frees it when done.
static func spawn_fx(parent: Node, frames: SpriteFrames, pos: Vector2, rot := 0.0, offset := Vector2.ZERO) -> AnimatedSprite2D:
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = frames
	fx.offset = offset
	fx.z_index = 5
	parent.add_child(fx)
	fx.global_position = pos
	fx.global_rotation = rot
	fx.animation_finished.connect(fx.queue_free)
	fx.play(&"play")
	return fx
