## Small math helpers shared by the kit (ports of src/00-util.js).
class_name PNoise
extends RefCounted


static func smooth(a: float, b: float, x: float) -> float:
	x = clampf((x - a) / (b - a), 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


static func hash2(x: float, y: float) -> float:
	var n := sin(x * 127.1 + y * 311.7) * 43758.5453
	return n - floorf(n)


static func vnoise2(x: float, y: float) -> float:
	var ix := floorf(x)
	var iy := floorf(y)
	var fx := x - ix
	var fy := y - iy
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	return lerpf(lerpf(hash2(ix, iy), hash2(ix + 1.0, iy), fx), lerpf(hash2(ix, iy + 1.0), hash2(ix + 1.0, iy + 1.0), fx), fy)


## sRGB hex (0xRRGGBB) -> linear Color, like C() in the original
static func C(hex: int) -> Color:
	return Color.hex((hex << 8) | 0xff).srgb_to_linear()


static func mixc(a: Color, b: Color, t: float) -> Color:
	return Color(lerpf(a.r, b.r, t), lerpf(a.g, b.g, t), lerpf(a.b, b.b, t))


## deterministic 0..1 random stream (mulberry32)
class Mulberry:
	var a: int
	func _init(seed: int) -> void:
		a = seed & 0xFFFFFFFF
	func next() -> float:
		a = (a + 0x6D2B79F5) & 0xFFFFFFFF
		var t := a
		t = _imul(t ^ (t >> 15), t | 1)
		t ^= (t + _imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF
		return float((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0
	static func _imul(x: int, y: int) -> int:
		return (x * y) & 0xFFFFFFFF
