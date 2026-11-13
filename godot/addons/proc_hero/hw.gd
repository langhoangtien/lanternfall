## Human wardrobe: body proportions and every garment / prop, as functions that add geometry to a ProcGeo.
## Port of src/20-human.js and src/20b-wardrobe.js.
##
## Convention: side = +1 is the figure's left (+X), -1 its right. P is a Dictionary {sh, hp} (shoulder / hip half width).
class_name HW
extends RefCounted

const G := preload("res://addons/proc_hero/geo.gd")

static var COL := {
	"mail": PNoise.C(0x70757a), "plate": PNoise.C(0x8b8f93), "iron": PNoise.C(0x34353a), "brass": PNoise.C(0x8a6a34),
	"linen": PNoise.C(0x857a60), "buff": PNoise.C(0x6e6148), "murrey": PNoise.C(0x4a1e22), "bone": PNoise.C(0x6e6857), "wool": PNoise.C(0x222a27),
	"woolBrown": PNoise.C(0x3c3026), "woolGrey": PNoise.C(0x44474a), "black": PNoise.C(0x1a1a1c),
	"leather": PNoise.C(0x40291a), "leatherDk": PNoise.C(0x271b13), "leatherTan": PNoise.C(0x6a4a2c), "waxed": PNoise.C(0x25221c),
	"skin": PNoise.C(0x6e5040), "skinDk": PNoise.C(0x3a2a22), "hair": PNoise.C(0x2a2018), "hairGrey": PNoise.C(0x6a665e), "fur": PNoise.C(0x4c3b2c),
	"furGrey": PNoise.C(0x5a5650), "wood": PNoise.C(0x5e4a32), "woodDk": PNoise.C(0x3a2c1e), "rope": PNoise.C(0x6a5c40),
}

# Body tables, ascending in y.
# torso: [y, half width, front depth, back depth, squareness]
static var TP := [[0.90, 0.168, 0.105, 0.115, 2.3], [0.98, 0.172, 0.11, 0.12, 2.3], [1.045, 0.152, 0.103, 0.102, 2.2], [1.1, 0.153, 0.105, 0.1, 2.2], [1.17, 0.162, 0.112, 0.1, 2.2], [1.27, 0.182, 0.125, 0.11, 2.3], [1.37, 0.198, 0.122, 0.112, 2.4], [1.44, 0.19, 0.105, 0.105, 2.5], [1.49, 0.11, 0.075, 0.085, 2.2], [1.525, 0.062, 0.06, 0.066, 2.0]]
# arm: [y, radius, x offset]
static var AP := [[0.905, 0.034, 0.03], [0.99, 0.042, 0.027], [1.07, 0.049, 0.023], [1.14, 0.047, 0.02], [1.22, 0.05, 0.016], [1.34, 0.058, 0.008], [1.43, 0.066, 0.004], [1.475, 0.058, 0], [1.5, 0.03, -0.015]]
# leg: [y, half width, front, back, x offset]
static var LP := [[0.1, 0.038, 0.04, 0.042, 0.005], [0.22, 0.044, 0.04, 0.05, 0.005], [0.34, 0.054, 0.046, 0.07, 0.005], [0.43, 0.052, 0.05, 0.06, 0.005], [0.5, 0.056, 0.06, 0.056, 0.005], [0.62, 0.066, 0.07, 0.068, 0.004], [0.76, 0.08, 0.088, 0.088, 0.002], [0.9, 0.09, 0.097, 0.1, 0], [0.99, 0.086, 0.095, 0.1, 0]]


static func samp(Tb: Array, y: float) -> Array:
	if y <= Tb[0][0]: return Tb[0]
	var n := Tb.size()
	if y >= Tb[n - 1][0]: return Tb[n - 1]
	for i in n - 1:
		var a: Array = Tb[i]
		var b: Array = Tb[i + 1]
		if y <= b[0]:
			var t: float = (y - a[0]) / (b[0] - a[0])
			var out := []
			for k in a.size(): out.append(lerpf(a[k], b[k], t))
			return out
	return Tb[n - 1]


## table rows clipped to [y0, y1]
static func span(Tb: Array, y0: float, y1: float) -> Array:
	var out := [samp(Tb, y0).duplicate()]
	for r: Array in Tb:
		if r[0] > y0 + 0.012 and r[0] < y1 - 0.012: out.append(r)
	out.append(samp(Tb, y1).duplicate())
	out[0][0] = y0
	out[out.size() - 1][0] = y1
	return out


static func BL(y: float) -> float:
	return PNoise.smooth(1.04, 1.1, y) * PNoise.smooth(1.3, 1.13, y)


static func TW() -> Callable:
	return G.chain_y([["neck", 9.0], ["chest", 1.5], ["spine", 1.27], ["hips", 1.1]], 0.05)


static func _arc(o: Dictionary, opt: Dictionary) -> void:
	for k in ["arc", "thick", "cap0", "cap1", "wr", "wra", "wry"]:
		if o.has(k): opt[k] = o[k]


# ======================================================================== body
## o: grow, y0, y1, k (width), kz (depth), belly, blouse, arc, thick, seg, wr...
static func torso(g: ProcGeo, o := {}) -> void:
	var gr: float = o.get("grow", 0.0)
	var k: float = o.get("k", 1.0)
	var kz: float = o.get("kz", k)
	var blouse: float = o.get("blouse", 0.0)
	var belly: float = o.get("belly", 0.0)
	g.bone(o.get("bone", TW()))
	var rings := []
	for r: Array in span(TP, o.get("y0", 0.9), o.get("y1", 1.525)):
		var y: float = r[0]
		rings.append({"y": y, "rx": r[1] * k + gr + blouse * BL(y),
			"rz": r[2] * kz + gr + belly * PNoise.smooth(0.28, 0.0, absf(y - 1.1)) + blouse * BL(y) * 1.2,
			"rb": r[3] * kz + gr + blouse * BL(y), "sq": r[4]})
	var opt := {"seg": o.get("seg", 18), "sub": 3}
	_arc(o, opt)
	g.loft(rings, opt)


static func arm(g: ProcGeo, P: Dictionary, side: int, o := {}) -> void:
	var gr: float = o.get("grow", 0.0)
	var k: float = o.get("k", 1.0)
	var U := "lUp" if side > 0 else "rUp"
	var F := "lFore" if side > 0 else "rFore"
	g.bone(o.get("bone", G.jb(U, F, 1.14, 0.05)))
	var rings := []
	for r: Array in span(AP, o.get("y0", 0.905), o.get("y1", 1.5)):
		rings.append({"y": r[0], "rx": r[1] * k + gr, "x": side * (P.sh + r[2])})
	var opt := {"seg": o.get("seg", 10), "sub": 3, "wra": 2.0, "wry": 55.0}
	_arc(o, opt)
	opt["cap1"] = o.get("cap1", not o.has("y1"))
	g.loft(rings, opt)


static func leg(g: ProcGeo, P: Dictionary, side: int, o := {}) -> void:
	var gr: float = o.get("grow", 0.0)
	var k: float = o.get("k", 1.0)
	var Tn := "lThigh" if side > 0 else "rThigh"
	var S := "lShin" if side > 0 else "rShin"
	g.bone(o.get("bone", G.jb(Tn, S, 0.5, 0.055)))
	var rings := []
	for r: Array in span(LP, o.get("y0", 0.1), o.get("y1", 0.99)):
		rings.append({"y": r[0], "rx": r[1] * k + gr, "rz": r[2] * k + gr, "rb": r[3] * k + gr, "x": side * (P.hp + r[4])})
	var opt := {"seg": o.get("seg", 12), "sub": 3, "wra": 2.0, "wry": 45.0}
	_arc(o, opt)
	g.loft(rings, opt)


static func boot(g: ProcGeo, P: Dictionary, side: int, o := {}) -> void:
	var x: float = side * (P.hp + 0.005)
	var S := "lShin" if side > 0 else "rShin"
	var F := "lFoot" if side > 0 else "rFoot"
	var top: float = o.get("top", 0.37)
	leg(g, P, side, {"y0": 0.07, "y1": top, "grow": 0.009, "bone": G.jb(S, F, 0.1, 0.035)})
	# folded cuff
	g.bone(S)
	var c := samp(LP, top)
	g.loft([{"y": top - 0.05, "rx": c[1] + 0.011, "rz": c[2] + 0.011, "rb": c[3] + 0.012, "x": x}, {"y": top - 0.02, "rx": c[1] + 0.015, "rz": c[2] + 0.015, "rb": c[3] + 0.016, "x": x},
		{"y": top + 0.01, "rx": c[1] + 0.013, "rz": c[2] + 0.013, "rb": c[3] + 0.014, "x": x}, {"y": top + 0.01, "rx": c[1] + 0.005, "rz": c[2] + 0.005, "rb": c[3] + 0.005, "x": x}], {"seg": 12, "sub": 2})
	# foot: lofted along +Z with a flat sole and a heel
	g.bone(F)
	g.tf(x, 0.056, 0.012, PI / 2)
	g.loft([{"y": -0.088, "rx": 0.026, "rz": 0.03, "rb": 0.03, "sq": 2.6}, {"y": -0.06, "rx": 0.042, "rz": 0.05, "rb": 0.05, "sq": 2.6}, {"y": -0.01, "rx": 0.047, "rz": 0.052, "rb": 0.062, "sq": 2.6},
		{"y": 0.05, "rx": 0.047, "rz": 0.05, "rb": 0.05, "sq": 2.5}, {"y": 0.11, "rx": 0.05, "rz": 0.046, "rb": 0.03, "sq": 2.4}, {"y": 0.165, "rx": 0.044, "rz": 0.04, "rb": 0.016, "sq": 2.3},
		{"y": 0.2, "rx": 0.032, "rz": 0.034, "rb": 0.004, "sq": 2.2}, {"y": 0.222, "rx": 0.014, "rz": 0.026, "rb": -0.006, "sq": 2.2}], {"seg": 12, "sub": 3, "cap0": true, "cap1": true, "wr": 0.06, "wra": 2.0, "wry": 30.0})
	g.pop()
	var m := g.save_mat()
	g.mat(COL.leatherDk, 0.9, 0, G.T_LEATHER, 1.6)
	g.tf(x, 0.015, 0.012, PI / 2)
	g.loft([{"y": -0.092, "rx": 0.036, "rz": 0.015, "sq": 3.0}, {"y": -0.06, "rx": 0.045, "rz": 0.015, "sq": 3.0}, {"y": -0.012, "rx": 0.046, "rz": 0.015, "sq": 3.0},
		{"y": -0.008, "rx": 0.044, "rz": 0.006, "rb": 0.015, "sq": 3.0}, {"y": 0.11, "rx": 0.052, "rz": 0.006, "rb": 0.012, "sq": 3.0}, {"y": 0.19, "rx": 0.04, "rz": 0.004, "rb": 0.01, "sq": 3.0},
		{"y": 0.226, "rx": 0.016, "rz": 0.002, "rb": 0.008, "sq": 3.0}], {"seg": 10, "sub": 2, "cap0": true, "cap1": true})
	g.load_mat(m)
	g.pop()


static func fist(g: ProcGeo, P: Dictionary, side: int) -> void:
	var x: float = side * (P.sh + 0.03)
	var Hn := "lHand" if side > 0 else "rHand"
	g.bone(Hn)
	g.loft([{"y": 0.782, "rx": 0.026, "rz": 0.036, "rb": 0.026, "x": x, "z": 0.006, "sq": 2.6}, {"y": 0.8, "rx": 0.037, "rz": 0.05, "rb": 0.036, "x": x, "z": 0.008, "sq": 3.0},
		{"y": 0.835, "rx": 0.04, "rz": 0.05, "rb": 0.04, "x": x, "z": 0.006, "sq": 3.0}, {"y": 0.868, "rx": 0.036, "rz": 0.04, "rb": 0.036, "x": x, "z": 0.002, "sq": 2.6},
		{"y": 0.89, "rx": 0.03, "rz": 0.03, "rb": 0.03, "x": x, "sq": 2.2}], {"seg": 10, "sub": 2, "cap0": true, "cap1": true})
	for k in 4:
		g.tf(x - side * 0.027 + side * k * 0.018, 0.812 + 0.004 * sin(k * 1.3), 0.05); g.sphere(0.0095, 0.02, 0.012, 5, 4); g.pop()
	g.tf(x - side * 0.03, 0.845, 0.034, 0.5); g.sphere(0.014, 0.03, 0.016, 6, 5); g.pop()
	g.bone(G.jb("lFore" if side > 0 else "rFore", Hn, 0.885, 0.02))
	g.tf(x); g.lathe([Vector2(0.036, 0.935), Vector2(0.038, 0.9), Vector2(0.04, 0.875), Vector2(0.03, 0.858)], 9); g.pop()


## skirt weights: sides follow the thighs, centre hangs from the hips
static func skirtW(yTop: float) -> Callable:
	return func(p: Vector3) -> Array:
		var t := PNoise.smooth(yTop, yTop - 0.24, p.y)
		var lf := PNoise.smooth(0.015, 0.075, absf(p.x))
		var L := p.x > 0
		if p.y < 0.52 and lf > 0.97:
			return ["lThigh" if L else "rThigh", "lShin" if L else "rShin", PNoise.smooth(0.52, 0.26, p.y) * 0.7]
		return ["hips", "lThigh" if L else "rThigh", t * lf]


## o: y0 (top), y1 (hem), grow, flare, arc, thick, wave, folds, seg, wTop
static func skirt(g: ProcGeo, o: Dictionary) -> void:
	var y0: float = o.y0
	var y1: float = o.y1
	var a := samp(TP, maxf(0.9, y0))
	var gr: float = o.get("grow", 0.0)
	var fl: float = o.get("flare", 0.05)
	g.bone(skirtW(o.get("wTop", y0)))
	var wave: float = o.get("wave", 0.0)
	var thick: float = o.get("thick", 0.008)
	if wave == 0.0:
		var rings := []
		for i in 6:
			var t := i / 5.0
			var f := 1.0 - t
			rings.append({"y": lerpf(y1, y0, t), "rx": a[1] + gr + fl * f, "rz": a[2] + gr + fl * f * 0.9, "rb": a[3] + gr + fl * f * 1.1, "sq": 2.3})
		var opt := {"seg": o.get("seg", 20), "sub": 2, "thick": thick}
		if o.has("arc"): opt["arc"] = o.arc
		g.loft(rings, opt)
		return
	# hem with soft folds
	var seg: int = o.get("seg", 28)
	var has_arc := o.has("arc")
	var a0: float = o.arc.x if has_arc else 0.0
	var a1: float = o.arc.y if has_arc else TAU
	var ax: float = a[1] + gr
	var az: float = a[2] + gr
	var ab: float = a[3] + gr
	var folds: float = o.get("folds", 9)
	g.surf(g._seg(seg), g._seg(8), func(u: float, v: float) -> Vector3:
		var y := lerpf(y1, y0, v)
		var f := 1.0 - v
		var an := a0 + (a1 - a0) * u
		var c := cos(an)
		var s := sin(an)
		var fold := 1.0 + wave * f * sin(an * folds + 1.3) + wave * 0.5 * f * sin(an * 17.0 + 4.0)
		return Vector3((ax + fl * f) * c * fold, y, ((az + fl * f * 0.9) if s >= 0.0 else (ab + fl * f * 1.1)) * s * fold), {"closeU": not has_arc, "thick": thick})


static func belt(g: ProcGeo, o := {}) -> void:
	var y: float = o.get("y", 1.045)
	var a := samp(TP, y)
	var gr: float = o.get("grow", 0.03)
	var w: float = o.get("w", 0.026)
	g.bone("hips"); g.mat(o.get("col", COL.leatherDk), 0.62, 0, G.T_LEATHER, 0.5)
	g.loft([{"y": y - w, "rx": a[1] + gr, "rz": a[2] + gr, "rb": a[3] + gr, "sq": 2.2}, {"y": y - w, "rx": a[1] + gr + 0.007, "rz": a[2] + gr + 0.007, "rb": a[3] + gr + 0.007, "sq": 2.2},
		{"y": y + w, "rx": a[1] + gr + 0.007, "rz": a[2] + gr + 0.007, "rb": a[3] + gr + 0.007, "sq": 2.2}, {"y": y + w, "rx": a[1] + gr, "rz": a[2] + gr, "rb": a[3] + gr, "sq": 2.2}], {"seg": 18, "sub": 1})
	# buckle + strap end
	g.mat(COL.brass, 0.45, 0.9, G.T_PLATE, 0.3)
	g.tf(0.015, y - 0.03, a[2] + gr + 0.006); g.loft([{"y": 0.0, "rx": 0.03, "rz": 0.006, "sq": 6.0}, {"y": 0.06, "rx": 0.03, "rz": 0.006, "sq": 6.0}], {"seg": 8, "sub": 1, "cap0": true, "cap1": true}); g.pop()
	g.mat(o.get("col", COL.leatherDk), 0.62, 0, G.T_LEATHER, 0.5)
	g.bone(skirtW(y)); g.tf(-0.03, y - 0.19, a[2] + gr + 0.012, 0.06, 0, 0.05)
	g.loft([{"y": 0.0, "rx": 0.012, "rz": 0.003, "sq": 5.0}, {"y": 0.19, "rx": 0.018, "rz": 0.004, "sq": 5.0}], {"seg": 8, "sub": 1, "cap0": true}); g.pop()


static func pouch(g: ProcGeo, x: float, y: float, z: float, s := 1.0, col: Variant = null) -> void:
	g.bone("hips"); g.mat(col if col != null else COL.leather, 0.7, 0, G.T_LEATHER, 0.6)
	g.tf(x, y, z, 0, atan2(x, z), 0, s)
	g.loft([{"y": -0.1, "rx": 0.045, "rz": 0.03, "sq": 3.0}, {"y": -0.06, "rx": 0.055, "rz": 0.04, "sq": 3.0}, {"y": 0.0, "rx": 0.05, "rz": 0.034, "sq": 3.0}], {"seg": 10, "sub": 2, "cap0": true, "cap1": true})
	g.surf(6, 3, func(u: float, v: float) -> Vector3: return Vector3((u - 0.5) * 0.1, 0.004 - v * 0.07, 0.036 + sin(v * 2.2) * 0.012), {"thick": 0.005})
	g.pop()


## head with a restrained face. o: beard (0..1 length), skin, hair, hairCap
static func head(g: ProcGeo, o := {}) -> void:
	var sk: Color = o.get("skin", COL.skin)
	g.bone(G.jb("head", "neck", 1.56, 0.02)); g.mat(sk, 0.62, 0, G.T_SKIN, 0.25)
	g.lathe([Vector2(0.05, 1.47), Vector2(0.049, 1.53), Vector2(0.052, 1.585)], 10)
	g.bone("head")
	g.loft([{"y": 1.548, "rx": 0.038, "rz": 0.058, "rb": 0.04, "z": 0.012}, {"y": 1.575, "rx": 0.057, "rz": 0.082, "rb": 0.066, "z": 0.008}, {"y": 1.62, "rx": 0.07, "rz": 0.093, "rb": 0.084, "z": 0.004},
		{"y": 1.675, "rx": 0.076, "rz": 0.097, "rb": 0.094}, {"y": 1.72, "rx": 0.078, "rz": 0.1, "rb": 0.1}, {"y": 1.765, "rx": 0.071, "rz": 0.09, "rb": 0.096},
		{"y": 1.795, "rx": 0.046, "rz": 0.06, "rb": 0.066}, {"y": 1.806, "rx": 0.012, "rz": 0.016, "rb": 0.016}], {"seg": 16, "sub": 3, "cap0": true, "cap1": true})
	# nose, brow
	g.loft([{"y": 1.648, "rx": 0.017, "rz": 0.03, "rb": 0.01, "z": 0.092}, {"y": 1.668, "rx": 0.014, "rz": 0.03, "rb": 0.01, "z": 0.092}, {"y": 1.7, "rx": 0.01, "rz": 0.016, "rb": 0.01, "z": 0.09},
		{"y": 1.722, "rx": 0.011, "rz": 0.012, "rb": 0.01, "z": 0.09}], {"seg": 8, "sub": 2, "cap0": true})
	g.tf(0, 1.722, 0.086); g.sphere(0.062, 0.012, 0.022, 10, 5); g.pop()
	g.mat(PNoise.mixc(sk, Color.BLACK, 0.78), 0.5, 0, G.T_SKIN, 0)
	for s in [-1, 1]:
		g.tf(s * 0.031, 1.699, 0.086); g.sphere(0.016, 0.008, 0.012, 8, 5); g.pop()
	g.tf(0, 1.612, 0.089); g.sphere(0.022, 0.004, 0.008, 8, 4); g.pop()
	if o.get("beard", 0.0) > 0.0:
		var b: float = o.beard
		g.mat(o.get("hair", COL.hair), 0.95, 0, G.T_FUR, 0.3)
		g.loft([{"y": 1.555 - b * 0.09, "rx": 0.02, "rz": 0.03, "rb": 0.0, "z": 0.05}, {"y": 1.565 - b * 0.04, "rx": 0.052, "rz": 0.062, "rb": 0.01, "z": 0.036}, {"y": 1.6, "rx": 0.075, "rz": 0.1, "rb": 0.03, "z": 0.004},
			{"y": 1.64, "rx": 0.079, "rz": 0.1, "rb": 0.03, "z": 0.002}, {"y": 1.665, "rx": 0.079, "rz": 0.086, "rb": 0.03}], {"seg": 14, "sub": 3, "arc": Vector2(-0.25, PI + 0.25), "cap0": true})
		g.tf(0, 1.632, 0.094); g.sphere(0.034, 0.011, 0.014, 8, 4); g.pop()  # moustache
	if o.get("hairCap", false):
		g.mat(o.get("hair", COL.hair), 0.95, 0, G.T_FUR, 0.2)
		g.loft([{"y": 1.6, "rx": 0.074, "rz": 0.03, "rb": 0.092, "z": -0.006}, {"y": 1.68, "rx": 0.082, "rz": 0.07, "rb": 0.102}, {"y": 1.74, "rx": 0.082, "rz": 0.098, "rb": 0.105},
			{"y": 1.79, "rx": 0.06, "rz": 0.075, "rb": 0.08}, {"y": 1.813, "rx": 0.01, "rz": 0.012, "rb": 0.012}], {"seg": 14, "sub": 3, "cap1": true})


## mail coif: hood + mantle over the shoulders
static func coif(g: ProcGeo, P: Dictionary, o := {}) -> void:
	g.mat(o.get("col", COL.mail), 0.5, 0.85, G.T_MAIL, 0.3)
	g.bone(G.chain_y([["head", 9.0], ["neck", 1.585], ["chest", 1.5]], 0.035))
	var win: float = o.get("window", 0.6)
	var lip: float = o.get("lip", 1.684)
	g.loft([{"y": lip, "rx": 0.089, "rz": 0.108, "rb": 0.104}, {"y": 1.74, "rx": 0.088, "rz": 0.106, "rb": 0.108}, {"y": 1.79, "rx": 0.066, "rz": 0.08, "rb": 0.086}, {"y": 1.816, "rx": 0.02, "rz": 0.03, "rb": 0.03}],
		{"seg": 16, "sub": 3, "arc": Vector2(PI / 2 + win, PI / 2 - win + TAU), "thick": 0.006})
	g.loft([{"y": 1.418, "rx": P.sh + 0.02, "rz": 0.145, "rb": 0.136, "sq": 2.5}, {"y": 1.455, "rx": P.sh - 0.02, "rz": 0.13, "rb": 0.126, "sq": 2.4}, {"y": 1.5, "rx": 0.118, "rz": 0.1, "rb": 0.104},
		{"y": 1.55, "rx": 0.084, "rz": 0.092, "rb": 0.088}, {"y": 1.61, "rx": 0.086, "rz": 0.108, "rb": 0.096}, {"y": lip, "rx": 0.089, "rz": 0.11, "rb": 0.104}],
		{"seg": 18, "sub": 3, "thick": 0.007, "wr": 0.05, "wra": 4.0, "wry": 40.0})


static func kettle(g: ProcGeo, o := {}) -> void:
	g.bone("head"); g.mat(o.get("col", COL.plate), 0.44, 1, G.T_PLATE, 0.5)
	g.tf(0, 1.748, 0.0, -0.03)
	g.loft([{"y": -0.052, "rx": 0.16, "rz": 0.168, "rb": 0.166}, {"y": -0.038, "rx": 0.158, "rz": 0.165, "rb": 0.164}, {"y": 0.0, "rx": 0.098, "rz": 0.114, "rb": 0.114}, {"y": 0.04, "rx": 0.094, "rz": 0.11, "rb": 0.112},
		{"y": 0.075, "rx": 0.074, "rz": 0.088, "rb": 0.09}, {"y": 0.094, "rx": 0.036, "rz": 0.044, "rb": 0.046}, {"y": 0.1, "rx": 0.004, "rz": 0.006, "rb": 0.006}], {"seg": 20, "sub": 1, "thick": 0.004})
	g.loft([{"y": 0.0, "rx": 0.006, "rz": 0.116, "rb": 0.116}, {"y": 0.07, "rx": 0.006, "rz": 0.094, "rb": 0.096}, {"y": 0.106, "rx": 0.005, "rz": 0.03, "rb": 0.03}], {"seg": 8, "sub": 2, "cap1": true})
	g.mat(COL.iron, 0.5, 1, G.T_PLATE, 0.3)
	if g.detail > 0.7:
		for i in 10:
			var a := i / 10.0 * TAU + 0.3
			g.tf(cos(a) * 0.1, 0.012, sin(a) * 0.116); g.sphere(0.006, 0.005, 0.006, 5, 3); g.pop()
	g.pop()


static func spaulder(g: ProcGeo, P: Dictionary, side: int, o := {}) -> void:
	var U := "lUp" if side > 0 else "rUp"
	var x: float = side * P.sh
	var s: float = o.get("s", 1.0)
	g.mat(o.get("col", COL.plate), 0.46, 1, G.T_PLATE, 0.5)
	var shell := func(y: float, r: float, ry: float, drop: float) -> void:
		g.surf(8, 5, func(u: float, v: float) -> Vector3:
			var a := (u - 0.5) * 2.5
			var b := v * 1.25
			var cx := sin(b)
			var cy := cos(b)
			return Vector3(x + side * (cx * r * cos(a) * 0.86 + 0.012), y + cy * ry - drop * v, sin(a) * cx * r * 1.12), {"thick": 0.005, "flip": side < 0})
	g.bone(func(_p: Vector3) -> Array: return ["chest", U, 0.45]); shell.call(1.428, 0.082 * s, 0.07 * s, 0.0)
	g.bone(func(_p: Vector3) -> Array: return ["chest", U, 0.8]); shell.call(1.39, 0.08 * s, 0.04 * s, 0.05)
	g.bone(U); shell.call(1.345, 0.074 * s, 0.03 * s, 0.05)


static func couter(g: ProcGeo, P: Dictionary, side: int, o := {}) -> void:
	var U := "lUp" if side > 0 else "rUp"
	var F := "lFore" if side > 0 else "rFore"
	var x: float = side * (P.sh + 0.02)
	g.mat(o.get("col", COL.plate), 0.46, 1, G.T_PLATE, 0.5); g.bone(func(_p: Vector3) -> Array: return [U, F, 0.5])
	g.tf(x, 1.14, -0.012)
	g.surf(8, 5, func(u: float, v: float) -> Vector3:
		var a := u * TAU
		var b := v * 1.5
		return Vector3(cos(a) * sin(b) * 0.06, sin(a) * sin(b) * 0.066, -cos(b) * 0.062), {"closeU": true, "thick": 0.004})
	g.pop()


static func vambrace(g: ProcGeo, P: Dictionary, side: int, o := {}) -> void:
	var F := "lFore" if side > 0 else "rFore"
	g.mat(o.get("col", COL.plate), o.get("rough", 0.46), o.get("metal", 1.0), o.get("ty", G.T_PLATE), 0.5)
	arm(g, P, side, {"y0": 0.93, "y1": 1.09, "grow": 0.012, "bone": F, "thick": 0.004, "cap1": false})


static func poleyn(g: ProcGeo, P: Dictionary, side: int, o := {}) -> void:
	var Tn := "lThigh" if side > 0 else "rThigh"
	var S := "lShin" if side > 0 else "rShin"
	var x: float = side * (P.hp + 0.005)
	g.mat(o.get("col", COL.plate), 0.46, 1, G.T_PLATE, 0.9); g.bone(func(_p: Vector3) -> Array: return [Tn, S, 0.5])
	g.tf(x, 0.5, 0.01)
	g.surf(8, 5, func(u: float, v: float) -> Vector3:
		var a := u * TAU
		var b := v * 1.45
		return Vector3(cos(a) * sin(b) * 0.06, sin(a) * sin(b) * 0.07, cos(b) * 0.066), {"closeU": true, "thick": 0.004})
	g.pop()
	leg(g, P, side, {"y0": 0.56, "y1": 0.8, "grow": 0.012, "arc": Vector2(0.25, PI - 0.25), "thick": 0.004, "bone": Tn})


static func greave(g: ProcGeo, P: Dictionary, side: int, o := {}) -> void:
	var S := "lShin" if side > 0 else "rShin"
	g.mat(o.get("col", COL.plate), 0.46, 1, G.T_PLATE, 1.2)
	leg(g, P, side, {"y0": 0.17, "y1": 0.45, "grow": 0.012, "arc": Vector2(-0.3, PI + 0.3), "thick": 0.004, "bone": S})


## cloak hanging from the shoulders. o: hem, wrap, col, flare, fold, clasp
static func cloak(g: ProcGeo, P: Dictionary, o := {}) -> void:
	var hem: float = o.get("hem", 0.42)
	var top := 1.5
	var wrap: float = o.get("wrap", 0.5)
	var flare: float = o.get("flare", 0.1)
	var foldk: float = o.get("fold", 0.085)
	g.mat(o.get("col", COL.wool), 0.95, 0, G.T_CLOTH, 1.5)
	g.bone(func(p: Vector3) -> Array:
		if p.y > 1.36: return ["chest", "cloakA", 1.0 - PNoise.smooth(1.36, 1.5, p.y)]
		if p.y > 1.02: return ["cloakA", "cloakB", 1.0 - PNoise.smooth(1.02, 1.36, p.y)]
		return ["cloakB", "cloakC", 1.0 - PNoise.smooth(0.66, 1.02, p.y)])
	var a0 := -PI / 2 - (PI / 2 + wrap)
	var a1 := -PI / 2 + (PI / 2 + wrap)
	var sh: float = P.sh
	g.surf(g._seg(38), g._seg(16), func(u: float, v: float) -> Vector3:
		var y := lerpf(top, hem, pow(v, 0.9))
		var f := v
		var a := lerpf(a0, a1, u)
		var back := maxf(0.0, -sin(a))
		var rx := lerpf(0.13, sh + 0.075, PNoise.smooth(0, 0.14, f)) + f * flare
		var rz := lerpf(0.1, 0.165, PNoise.smooth(0, 0.14, f)) + f * flare * 0.9
		var nz := PNoise.vnoise2(a * 2.1 + 3.3, 0.5)
		var fold := 1.0 + foldk * PNoise.smooth(0.1, 0.75, f) * (sin(a * 9.0 + 0.7 + nz * 5.0) * (0.5 + nz) + 0.5 * sin(a * 19.0 + 2.0)) + 0.04 * (PNoise.vnoise2(a * 3.0, y * 6.0) - 0.5)
		var drop := (1.0 - back) * 0.03 * f
		var rag := PNoise.smooth(0.8, 1, f) * (0.05 * PNoise.vnoise2(a * 6.0 + 1.0, 2.2) + 0.035 * PNoise.vnoise2(a * 17.0, 5.1))
		return Vector3(cos(a) * rx * fold, y + drop + rag + sin(a * 7.0) * 0.012 * f, sin(a) * rz * fold - 0.012 - 0.05 * f * back), {"thick": 0.007})
	if o.get("clasp", true):
		g.bone("chest"); g.mat(COL.brass, 0.45, 0.9, G.T_PLATE, 0.2); g.tf(0, 1.462, 0.108); g.sphere(0.02, 0.02, 0.008, 8, 5); g.pop()


## cloth hood with an oval, shadowed face opening, and a short mantle
static func hood(g: ProcGeo, P: Dictionary, o := {}) -> void:
	g.mat(o.get("col", COL.wool), 0.95, 0, G.T_CLOTH, 0.6)
	g.bone(G.chain_y([["head", 9.0], ["neck", 1.6], ["chest", 1.51]], 0.04))
	var op0: float = o.get("open", 0.7)
	var yc := 1.672
	var hy := 0.118
	var pk: float = o.get("peak", 0.05)
	g.surf(g._seg(30), g._seg(16), func(u: float, v: float) -> Vector3:
		var y := lerpf(1.5, 1.855, v)
		var q := (y - yc) / hy
		var op := op0 * sqrt(1.0 - q * q) if absf(q) < 1.0 else 0.0
		var a := lerpf(PI / 2 + op, PI / 2 - op + TAU, u)
		var e := absf(u - 0.5) * 2.0
		var fr := PNoise.smooth(0.62, 1, e) * (1.0 if op > 0.02 else 0.4)
		var tt := clampf((y - 1.73) / 0.125, 0, 1)
		var dome := sqrt(maxf(0.0, 1.0 - tt * tt))
		var low := PNoise.smooth(1.6, 1.5, y)
		var rx := (0.106 + 0.012 * sin(clampf((y - 1.5) / 0.25, 0, 1) * PI)) * dome + 0.012 * low + 0.004
		var rz := (0.118 + fr * 0.04) * dome + 0.004 + 0.01 * low
		var rb := (0.122 + pk * PNoise.smooth(1.62, 1.76, y)) * (0.25 + 0.75 * dome) + 0.012 * low
		var s := sin(a)
		var c := cos(a)
		var wr := 1.0 + 0.03 * sin(a * 7.0 + y * 30.0) + 0.02 * sin(a * 13.0)
		return Vector3(c * rx * wr, y + fr * 0.012 * (1.0 - v) - 0.012 * tt * tt * maxf(0.0, -s), (rz if s >= 0.0 else rb) * s * wr + 0.008), {"thick": 0.01})
	g.bone(G.chain_y([["neck", 9.0], ["chest", 1.5]], 0.04))
	var sh: float = P.sh
	g.surf(g._seg(26), 6, func(u: float, v: float) -> Vector3:
		var a := u * TAU
		var y := lerpf(1.54, 1.35, v)
		var f := PNoise.smooth(0, 1, v)
		var rx := lerpf(0.1, sh + 0.09, pow(f, 0.7))
		var rz := lerpf(0.1, 0.172, pow(f, 0.7))
		var w := 1.0 + 0.04 * f * sin(a * 9.0 + 1.0) + 0.025 * f * sin(a * 17.0)
		return Vector3(cos(a) * rx * w, y + 0.014 * sin(a * 5.0) * f - 0.02 * f * maxf(0.0, sin(a)), sin(a) * rz * w), {"closeU": true, "thick": 0.009})


# ======================================================================== carried things
## sword in a hand; blade along +Z (bind). o: len, w, grip, guard, col. returns {tip, base}
static func sword(g: ProcGeo, P: Dictionary, side: int, o := {}) -> Dictionary:
	var x: float = side * (P.sh + 0.03)
	var y := 0.835
	var len: float = o.get("len", 0.8)
	var w: float = o.get("w", 0.026)
	var gl: float = o.get("grip", 0.1)
	var guard: float = o.get("guard", 0.1)
	g.bone("wL" if side > 0 else "wR")
	g.tf(x, y, 0, PI / 2)  # local +Y -> world +Z
	g.mat(COL.leatherDk, 0.7, 0, G.T_LEATHER, 0.2); g.lathe([Vector2(0.013, -gl * 0.62), Vector2(0.016, -gl * 0.3), Vector2(0.015, 0), Vector2(0.013, gl * 0.4)], 8)
	g.mat(COL.iron, 0.42, 1, G.T_PLATE, 0.2); g.tf(0, -gl * 0.62 - 0.018, 0); g.sphere(0.024, 0.02, 0.024, 8, 6); g.pop()
	g.loft([{"y": gl * 0.4, "rx": 0.012, "rz": guard, "sq": 3.0}, {"y": gl * 0.4 + 0.016, "rx": 0.011, "rz": guard * 0.96, "sq": 3.0}], {"seg": 8, "sub": 1, "cap0": true, "cap1": true})
	g.mat(o.get("col", PNoise.C(0xa9adb2)), 0.3, 1, G.T_PLATE, 0.25)
	var y0 := gl * 0.4 + 0.016
	g.loft([{"y": y0, "rx": 0.0045, "rz": w, "sq": 1.0}, {"y": y0 + len * 0.6, "rx": 0.004, "rz": w * 0.82, "sq": 1.0}, {"y": y0 + len * 0.9, "rx": 0.003, "rz": w * 0.55, "sq": 1.0}, {"y": y0 + len, "rx": 0.0005, "rz": 0.002, "sq": 1.0}], {"seg": 4, "sub": 1, "flat": true})
	g.pop()
	return {"tip": Vector3(x, y, y0 + len), "base": Vector3(x, y, 0.06)}


## heater shield strapped to the forearm; face +X, top toward +Z (bind)
static func shield(g: ProcGeo, P: Dictionary, side: int, o := {}) -> void:
	var F := "lFore" if side > 0 else "rFore"
	var x0: float = side * (P.sh + 0.105)
	var yc := 1.02
	var hw: float = o.get("hw", 0.3)
	var hh: float = o.get("h", 0.86)
	g.bone(F)
	var prof := func(t: float) -> float: return 1.0 if t < 0.3 else pow(cos((t - 0.3) / 0.7 * PI / 2), 0.72)
	g.mat(COL.woodDk, 0.8, 0, G.T_WOOD, 0.5)
	g.surf(12, 12, func(u: float, v: float) -> Vector3:
		var s := (u - 0.5) * 2.0
		var yy: float = s * hw * prof.call(v)
		return Vector3(x0 + side * (0.07 - yy * yy * 0.75), yc + yy, hh * 0.42 - v * hh), {"thick": 0.016, "flip": side < 0})
	var half := func(s0: float, s1: float, col: Color) -> void:
		g.mat(col, 0.72, 0, G.T_CLOTH, 0.9)
		g.surf(6, 12, func(u: float, v: float) -> Vector3:
			var yy: float = lerpf(s0, s1, u) * hw * prof.call(v) * 0.965
			return Vector3(x0 + side * (0.073 - yy * yy * 0.75), yc + yy, hh * 0.42 - 0.012 - v * hh * 0.972), {"flip": side < 0})
	half.call(-1.0, 0.0, o.get("colA", COL.murrey)); half.call(0.0, 1.0, o.get("colB", COL.bone))
	g.mat(COL.iron, 0.5, 1, G.T_PLATE, 0.6)
	if g.detail > 0.7:
		var N := 26
		for i in N:
			var t := float(i) / N
			var v := t * 2.0 if t < 0.5 else (1.0 - t) * 2.0
			var sgn := 1.0 if t < 0.5 else -1.0
			var yy: float = sgn * hw * prof.call(v) * 0.93
			g.tf(x0 + side * (0.076 - yy * yy * 0.75), yc + yy, hh * 0.42 - 0.02 - v * hh * 0.95); g.sphere(0.008, 0.008, 0.008, 5, 3); g.pop()
	g.mat(COL.leather, 0.7, 0, G.T_LEATHER, 0.3)
	g.tf(side * (P.sh + 0.035), 1.07, 0); g.lathe([Vector2(0.062, -0.014), Vector2(0.064, 0), Vector2(0.062, 0.014)], 8, {"thick": 0.004}); g.pop()
	g.tf(side * (P.sh + 0.04), 0.94, 0); g.lathe([Vector2(0.056, -0.014), Vector2(0.058, 0), Vector2(0.056, 0.014)], 8, {"thick": 0.004}); g.pop()


static func scabbard(g: ProcGeo, P: Dictionary, side: int) -> void:
	g.bone(skirtW(1.02))
	var x := side * 0.19
	g.tf(x, 1.0, 0.02, -1.15 + PI, 0, side * 0.12)
	g.mat(COL.leatherDk, 0.66, 0, G.T_LEATHER, 0.8)
	g.loft([{"y": 0.0, "rx": 0.012, "rz": 0.03, "sq": 2.6}, {"y": 0.6, "rx": 0.01, "rz": 0.024, "sq": 2.6}, {"y": 0.74, "rx": 0.006, "rz": 0.012, "sq": 2.6}], {"seg": 8, "sub": 1, "cap1": true})
	g.mat(COL.iron, 0.5, 1, G.T_PLATE, 0.5)
	g.loft([{"y": -0.005, "rx": 0.014, "rz": 0.033, "sq": 2.6}, {"y": 0.05, "rx": 0.014, "rz": 0.032, "sq": 2.6}], {"seg": 8, "sub": 1, "cap0": true})
	g.loft([{"y": 0.66, "rx": 0.011, "rz": 0.02, "sq": 2.6}, {"y": 0.76, "rx": 0.006, "rz": 0.01, "sq": 2.6}], {"seg": 8, "sub": 1, "cap1": true})
	g.pop()


## hanging lantern around (x,y,z), hangs along -Y. The bone should be an absolute bone (lan / lanB).
static func lantern_body(g: ProcGeo, bone_name: String, x: float, y: float, z: float, s := 1.0) -> void:
	g.bone(bone_name); g.tf(x, y, z, 0, 0, 0, s)
	g.mat(COL.iron, 0.55, 0.9, G.T_PLATE, 0.2)
	g.tube([Vector3(0, 0, 0), Vector3(0, -0.07, 0)], 0.006, {"seg": 4, "sub": 1})
	g.tf(0, -0.045, 0, PI / 2); g.lathe([Vector2(0.02, -0.004), Vector2(0.024, 0), Vector2(0.02, 0.004)], 8, {"thick": 0.004}); g.pop()
	g.lathe([Vector2(0.0, -0.07), Vector2(0.02, -0.075), Vector2(0.035, -0.1), Vector2(0.085, -0.14), Vector2(0.09, -0.155), Vector2(0.07, -0.155)], 8)
	g.lathe([Vector2(0.07, -0.365), Vector2(0.085, -0.365), Vector2(0.085, -0.385), Vector2(0.05, -0.39), Vector2(0.02, -0.41), Vector2(0.0, -0.415)], 8)
	for i in 4:
		var a := i / 4.0 * TAU + PI / 4
		g.tube([Vector3(cos(a) * 0.076, -0.155, sin(a) * 0.076), Vector3(cos(a) * 0.076, -0.365, sin(a) * 0.076)], 0.007, {"seg": 4, "sub": 1})
	for yy in [-0.2, -0.32]:
		g.lathe([Vector2(0.078, yy - 0.004), Vector2(0.082, yy), Vector2(0.078, yy + 0.004)], 8)
	g.mat(PNoise.C(0xffb055), 0.4, 0, G.T_GLOW, 1.0)
	g.lathe([Vector2(0.0, -0.165), Vector2(0.064, -0.165), Vector2(0.064, -0.36), Vector2(0.0, -0.36)], 8)
	g.pop()


## rolled cloth around the neck and shoulders. o: col, r, y, wide, hood
static func cowl(g: ProcGeo, P: Dictionary, o := {}) -> void:
	g.mat(o.get("col", COL.wool), 0.95, 0, G.T_CLOTH, 0.5); g.bone(G.chain_y([["neck", 9.0], ["chest", 1.52]], 0.04))
	var r: float = o.get("r", 0.034)
	var y: float = o.get("y", 1.485)
	var wide: float = o.get("wide", 0.0)
	var N := 20
	var pts := []
	for i in N + 1:
		var a := float(i) / N * TAU + PI / 2
		var c := cos(a)
		var s := sin(a)
		pts.append(Vector3(c * (0.118 + wide), y + (-0.035 * s if s > 0 else -0.012 * s) + 0.008 * sin(a * 5.0), s * (0.112 if s > 0 else 0.118) - 0.004))
	g.tube(pts, func(t: float) -> float: return r * (0.8 + 0.3 * sin(t * 23.0) * sin(t * 7.0)), {"seg": 8, "sub": 1, "cap": false})


## a strap around the torso (baldric / bandolier). o: side, w, grow, col
static func strap(g: ProcGeo, o := {}) -> void:
	var s: float = o.get("side", 1)
	var w: float = o.get("w", 0.017)
	var gr: float = o.get("grow", 0.04)
	g.bone(TW()); g.mat(o.get("col", COL.leather), 0.66, 0, G.T_LEATHER, 0.5)
	var N := 22
	var pts := []
	for i in N + 1:
		var a := float(i) / N * TAU
		var yy := 1.25 + 0.2 * cos(a)
		var r := samp(TP, yy)
		var c := cos(a)
		pts.append(Vector3(s * c * (r[1] * 0.92 + gr * 0.6) * (0.55 + 0.45 * absf(c)), yy, sin(a) * ((r[2] if sin(a) > 0 else r[3]) + gr)))
	g.tube(pts, w, {"seg": 6, "sub": 1, "cap": false, "flatten": 0.35})


# ======================================================================== wardrobe part two
static func skullcap(g: ProcGeo, o := {}) -> void:
	g.bone("head"); g.mat(o.get("col", COL.iron), 0.5, 1, G.T_PLATE, 0.8)
	g.loft([{"y": 1.7, "rx": 0.088, "rz": 0.108, "rb": 0.108}, {"y": 1.75, "rx": 0.086, "rz": 0.104, "rb": 0.106}, {"y": 1.795, "rx": 0.066, "rz": 0.08, "rb": 0.084}, {"y": 1.822, "rx": 0.02, "rz": 0.03, "rb": 0.03}, {"y": 1.826, "rx": 0.002, "rz": 0.003, "rb": 0.003}], {"seg": 16, "sub": 3, "thick": 0.004})
	g.loft([{"y": 1.698, "rx": 0.091, "rz": 0.111, "rb": 0.111}, {"y": 1.716, "rx": 0.091, "rz": 0.111, "rb": 0.111}], {"seg": 16, "sub": 1, "thick": 0.004})
	g.loft([{"y": 1.63, "rx": 0.011, "rz": 0.006, "z": 0.118}, {"y": 1.705, "rx": 0.014, "rz": 0.006, "z": 0.108}], {"seg": 6, "sub": 1, "cap0": true})
	for i in 4:
		var a := i / 4.0 * TAU + PI / 4
		g.tube([Vector3(cos(a) * 0.088, 1.71, sin(a) * 0.107), Vector3(cos(a) * 0.07, 1.785, sin(a) * 0.086), Vector3(0, 1.828, 0)], 0.006, {"seg": 4, "sub": 2})


## wide weatherbeaten hat
static func hat(g: ProcGeo, o := {}) -> void:
	g.bone("head"); g.mat(o.get("col", COL.waxed), 0.8, 0, G.T_LEATHER, 0.5)
	g.tf(0, 1.735, 0, -0.1, 0, 0.04)
	g.surf(g._seg(26), g._seg(12), func(u: float, v: float) -> Vector3:
		var a := u * TAU
		var c := cos(a)
		var s := sin(a)
		if v < 0.45:
			var t := v / 0.45
			var r := lerpf(0.3, 0.1, t)
			var droop := (1.0 - t) * (0.05 + 0.035 * sin(a * 2.0 + 1.0) + 0.02 * sin(a * 5.0))
			return Vector3(c * r * (1.0 + 0.05 * sin(a * 3.0)), -droop + t * 0.01, s * r * 1.08)
		var t := (v - 0.45) / 0.55
		var r := lerpf(0.1, 0.05, pow(t, 1.6))
		var y := 0.01 + 0.13 * sin(t * PI / 2)
		return Vector3(c * r + 0.012 * t * sin(a * 2.0), y - 0.012 * t * cos(a), s * r * 1.12 - 0.02 * t), {"closeU": true, "thick": 0.006})
	g.mat(COL.leatherDk, 0.7, 0, G.T_LEATHER, 0.3); g.lathe([Vector2(0.103, 0.012), Vector2(0.106, 0.03), Vector2(0.1, 0.045)], 14)
	g.pop()


## cloth wrap over the lower face
static func veil(g: ProcGeo, o := {}) -> void:
	g.bone("head"); g.mat(o.get("col", COL.woolGrey), 0.95, 0, G.T_CLOTH, 0.5)
	g.loft([{"y": 1.535, "rx": 0.062, "rz": 0.075, "rb": 0.07}, {"y": 1.58, "rx": 0.068, "rz": 0.098, "rb": 0.078}, {"y": 1.63, "rx": 0.08, "rz": 0.108, "rb": 0.092}, {"y": o.get("top", 1.676), "rx": 0.083, "rz": 0.108, "rb": 0.1}],
		{"seg": 14, "sub": 3, "thick": 0.006, "wr": 0.07, "wra": 3.0, "wry": 60.0})


static func fur_mantle(g: ProcGeo, P: Dictionary, o := {}) -> void:
	g.mat(o.get("col", COL.fur), 1, 0, G.T_FUR, 0.8); g.bone(G.chain_y([["neck", 9.0], ["chest", 1.53]], 0.04))
	var back_k: float = o.get("back", 0.14)
	var sh: float = P.sh
	g.surf(g._seg(24), 6, func(u: float, v: float) -> Vector3:
		var a := u * TAU
		var c := cos(a)
		var s := sin(a)
		var f := pow(v, 0.8)
		var back := maxf(0.0, -s)
		var y := lerpf(1.55, 1.36 - back_k * back, f) + 0.012 * sin(a * 13.0) * f
		var rx := lerpf(0.09, sh + 0.1, pow(f, 0.6))
		var rz := lerpf(0.09, 0.16 + 0.03 * back, pow(f, 0.6))
		var puff := 1.0 + 0.07 * sin(v * PI) + 0.045 * PNoise.vnoise2(a * 5.0, v * 4.0)
		return Vector3(c * rx * puff, y, s * rz * puff - 0.01), {"closeU": true, "thick": 0.02})


## arrow from (x,y,z) pointing along -Y
static func arrow(g: ProcGeo, x: float, y: float, z: float, len: float) -> void:
	g.mat(COL.wood, 0.7, 0, G.T_WOOD, 0); g.tube([Vector3(x, y, z), Vector3(x, y - len, z)], 0.0042, {"seg": 4, "sub": 1})
	g.mat(COL.iron, 0.4, 1, G.T_PLATE, 0); g.tf(x, y - len, z, PI); g.lathe([Vector2(0.008, 0), Vector2(0.006, 0.02), Vector2(0, 0.05)], 4); g.pop()
	g.mat(COL.bone, 0.9, 0, G.T_CLOTH, 0)
	for i in 3:
		var a := i / 3.0 * TAU
		g.surf(2, 1, func(u: float, v: float) -> Vector3:
			var w := 0.004 + v * 0.016 * sin(u * PI * 0.8 + 0.3)
			return Vector3(x + cos(a) * w, y - 0.02 - u * 0.09, z + sin(a) * w))


## bow in the left hand (bind: stave along Z, string toward +Y)
static func bow(g: ProcGeo, P: Dictionary, o := {}) -> Dictionary:
	var x: float = P.sh + 0.03
	var y := 0.835
	var L: float = o.get("len", 0.92)
	var br := 0.16
	g.bone("wL"); g.mat(COL.wood, 0.6, 0, G.T_WOOD, 0.3)
	var pts := []
	for i in 13:
		var t := i / 12.0 * 2.0 - 1.0
		pts.append(Vector3(x, y + br * t * t * (0.8 + 0.2 * absf(t)), t * L))
	g.tube(pts, func(t: float) -> float: return 0.0085 + 0.0095 * sin(t * PI), {"seg": 6, "sub": 2})
	g.mat(COL.leatherDk, 0.7, 0, G.T_LEATHER, 0.2); g.tube([Vector3(x, y, -0.06), Vector3(x, y, 0.06)], 0.018, {"seg": 7, "sub": 1})
	g.mat(COL.bone, 0.8, 0, G.T_CLOTH, 0)
	for sg in [-1, 1]:
		g.bone(func(p: Vector3) -> Array: return ["str", "wL", absf(p.z) / L])
		g.tube([Vector3(x, y + br, 0), Vector3(x, y + br, sg * L * 0.5), Vector3(x, y + br, sg * L)], 0.0028, {"seg": 3, "sub": 1, "cap": false})
	g.bone("arw"); arrow(g, x, y + br, 0, 0.78)
	return {"nock": Vector3(x, y + br, 0)}


static func quiver(g: ProcGeo) -> void:
	g.bone("chest")
	g.tf(-0.1, 1.2, -0.17, 0.12, 0, 0.42)
	g.mat(COL.leather, 0.7, 0, G.T_LEATHER, 0.6); g.lathe([Vector2(0.03, -0.3), Vector2(0.045, -0.28), Vector2(0.052, 0.0), Vector2(0.058, 0.3), Vector2(0.05, 0.3)], 9, {"cap0": true})
	g.mat(COL.leatherDk, 0.7, 0, G.T_LEATHER, 0.3)
	g.lathe([Vector2(0.06, 0.26), Vector2(0.062, 0.28), Vector2(0.06, 0.3)], 9); g.lathe([Vector2(0.05, -0.2), Vector2(0.052, -0.18), Vector2(0.05, -0.16)], 9)
	var r := PNoise.Mulberry.new(5)
	var n := 9 if g.detail > 0.7 else 5
	for i in n:
		var a := r.next() * TAU
		var d := r.next() * 0.034
		g.tf(cos(a) * d, 0.3 + 0.12 + r.next() * 0.05, sin(a) * d, (r.next() - 0.5) * 0.12, r.next() * 3.0, (r.next() - 0.5) * 0.12)
		arrow(g, 0, 0, 0, 0.3); g.pop()
	g.pop()


static func satchel(g: ProcGeo, x: float, y: float, z: float, ry: float, s := 1.0, col: Variant = null) -> void:
	g.bone(skirtW(1.04)); g.tf(x, y, z, 0, ry, 0, s)
	g.mat(col if col != null else COL.leatherTan, 0.75, 0, G.T_LEATHER, 0.8)
	g.loft([{"y": -0.2, "rx": 0.1, "rz": 0.035, "sq": 3.5}, {"y": -0.12, "rx": 0.115, "rz": 0.05, "sq": 3.5}, {"y": 0.0, "rx": 0.11, "rz": 0.04, "sq": 3.5}], {"seg": 10, "sub": 2, "cap0": true, "cap1": true, "wr": 0.08, "wra": 2.0, "wry": 20.0})
	g.surf(6, 4, func(u: float, v: float) -> Vector3: return Vector3((u - 0.5) * 0.23, 0.006 - v * 0.13, 0.046 + sin(v * 2.4) * 0.016), {"thick": 0.006})
	g.mat(COL.brass, 0.5, 0.9, G.T_PLATE, 0.3); g.tf(0, -0.11, 0.066); g.sphere(0.012, 0.012, 0.006, 6, 4); g.pop()
	g.pop()


static func flask(g: ProcGeo, x: float, y: float, z: float, s: float, col: Color, glow: float, bone_: Variant, rx := 0.0, rz := 0.0) -> void:
	g.bone(bone_ if bone_ != null else "chest"); g.tf(x, y, z, rx, 0, rz, s)
	if glow > 0.0: g.mat(col, 0.3, 0, G.T_GLOW, glow)
	else: g.mat(col, 0.35, 0, G.T_STONE, 0)
	g.lathe([Vector2(0.0, -0.045), Vector2(0.02, -0.043), Vector2(0.026, -0.02), Vector2(0.024, 0.01), Vector2(0.01, 0.028), Vector2(0.009, 0.045)], 8, {"cap0": true})
	g.mat(COL.wood, 0.8, 0, G.T_WOOD, 0); g.lathe([Vector2(0.011, 0.043), Vector2(0.012, 0.058), Vector2(0.0, 0.06)], 6)
	g.pop()


static func pack(g: ProcGeo) -> void:
	g.bone("back")
	g.mat(COL.leatherTan, 0.8, 0, G.T_LEATHER, 1); g.tf(0, 1.08, -0.2)
	g.loft([{"y": 0.0, "rx": 0.15, "rz": 0.07, "rb": 0.1, "sq": 3.2}, {"y": 0.16, "rx": 0.17, "rz": 0.07, "rb": 0.13, "sq": 3.2}, {"y": 0.36, "rx": 0.15, "rz": 0.07, "rb": 0.11, "sq": 3.2}, {"y": 0.42, "rx": 0.1, "rz": 0.06, "rb": 0.07, "sq": 3.0}], {"seg": 12, "sub": 3, "cap0": true, "cap1": true, "wr": 0.09, "wra": 2.0, "wry": 14.0})
	g.mat(COL.woolGrey, 0.95, 0, G.T_CLOTH, 0.8); g.tf(0, 0.47, -0.02, 0, 0, PI / 2); g.lathe([Vector2(0.0, -0.19), Vector2(0.055, -0.185), Vector2(0.06, 0), Vector2(0.055, 0.185), Vector2(0.0, 0.19)], 10); g.pop()
	g.mat(COL.leatherDk, 0.7, 0, G.T_LEATHER, 0.4)
	for sx in [-0.1, 0.1]:
		g.tube([Vector3(sx, 0.4, -0.1), Vector3(sx, 0.53, -0.02), Vector3(sx, 0.42, 0.06)], 0.008, {"seg": 4, "sub": 3, "cap": false})
	g.mat(COL.iron, 0.5, 0.9, G.T_PLATE, 0.6); g.tf(0.17, 0.12, -0.03, 0, 0, 0.2); g.lathe([Vector2(0.0, -0.06), Vector2(0.05, -0.055), Vector2(0.058, 0.03), Vector2(0.05, 0.034)], 8); g.pop()
	g.pop()
	g.bone("chest"); g.mat(COL.leatherDk, 0.7, 0, G.T_LEATHER, 0.4)
	for sx in [-1, 1]:
		g.tube([Vector3(sx * 0.1, 1.42, -0.14), Vector3(sx * 0.12, 1.5, -0.02), Vector3(sx * 0.13, 1.44, 0.11), Vector3(sx * 0.15, 1.24, 0.125), Vector3(sx * 0.16, 1.15, 0.0), Vector3(sx * 0.12, 1.14, -0.13)], 0.014, {"seg": 5, "sub": 3, "cap": false, "flatten": 0.4})


## staff / pole in a hand, along Z (bind). o: z0, z1, head ("crook" | "shard" | ""), col. returns the head point
static func staff(g: ProcGeo, P: Dictionary, side: int, o := {}) -> Vector3:
	var x: float = side * (P.sh + 0.03)
	var y := 0.835
	var z0: float = o.get("z0", -1.1)
	var z1: float = o.get("z1", 1.4)
	g.bone("wL" if side > 0 else "wR"); g.mat(o.get("col", COL.wood), 0.8, 0, G.T_WOOD, 0.4)
	g.tube([Vector3(x, y, z0), Vector3(x + 0.008, y, z0 * 0.4), Vector3(x - 0.006, y + 0.004, z1 * 0.5), Vector3(x, y, z1)], func(t: float) -> float: return 0.017 - 0.004 * t, {"seg": 7, "sub": 3})
	g.mat(COL.iron, 0.55, 0.9, G.T_PLATE, 0.6); g.tube([Vector3(x, y, z0), Vector3(x, y, z0 + 0.08)], 0.02, {"seg": 6, "sub": 1})
	var head_: String = o.get("head", "")
	if head_ == "crook":
		g.tube([Vector3(x, y, z1 - 0.08), Vector3(x, y, z1 + 0.06), Vector3(x, y - 0.07, z1 + 0.12), Vector3(x, y - 0.16, z1 + 0.06), Vector3(x, y - 0.17, z1 - 0.02)], 0.009, {"seg": 5, "sub": 4})
		g.tube([Vector3(x, y, z1 - 0.1), Vector3(x, y, z1 - 0.04)], 0.021, {"seg": 6, "sub": 1})
		return Vector3(x, y - 0.17, z1 - 0.02)
	if head_ == "shard":
		for i in 3:
			var a := i / 3.0 * TAU
			g.tube([Vector3(x, y, z1 - 0.06), Vector3(x + cos(a) * 0.035, y + sin(a) * 0.035, z1 + 0.02), Vector3(x + cos(a) * 0.03, y + sin(a) * 0.03, z1 + 0.1)], 0.006, {"seg": 4, "sub": 3})
		g.mat(PNoise.C(0xa8d8ff), 0.2, 0, G.T_GLOW, 0.8)
		g.tf(x, y, z1 + 0.02, PI / 2); g.loft([{"y": 0.0, "rx": 0.012, "rz": 0.012}, {"y": 0.06, "rx": 0.034, "rz": 0.028}, {"y": 0.15, "rx": 0.026, "rz": 0.03}, {"y": 0.26, "rx": 0.002, "rz": 0.002}], {"seg": 5, "sub": 1, "flat": true}); g.pop()
		g.tf(x + 0.02, y - 0.012, z1 + 0.03, PI / 2 + 0.25, 0, 0.3); g.loft([{"y": 0.0, "rx": 0.008, "rz": 0.008}, {"y": 0.04, "rx": 0.016, "rz": 0.014}, {"y": 0.13, "rx": 0.001, "rz": 0.001}], {"seg": 4, "sub": 1, "flat": true}); g.pop()
		return Vector3(x, y, z1 + 0.14)
	return Vector3(x, y, z1)


## long sleeve that flares at the wrist
static func bell_sleeve(g: ProcGeo, P: Dictionary, side: int) -> void:
	var x: float = side * P.sh
	g.bone(G.jb("lUp" if side > 0 else "rUp", "lFore" if side > 0 else "rFore", 1.14, 0.05))
	g.loft([{"y": 0.9, "rx": 0.075, "rz": 0.085, "rb": 0.075, "x": x + side * 0.03}, {"y": 0.96, "rx": 0.068, "x": x + side * 0.027}, {"y": 1.07, "rx": 0.062, "x": x + side * 0.023},
		{"y": 1.14, "rx": 0.062, "x": x + side * 0.02}, {"y": 1.3, "rx": 0.068, "x": x + side * 0.01}, {"y": 1.43, "rx": 0.076, "x": x + side * 0.004}, {"y": 1.48, "rx": 0.062, "x": x}, {"y": 1.505, "rx": 0.03, "x": x - side * 0.015}],
		{"seg": 12, "sub": 3, "thick": 0.006, "cap1": true, "wr": 0.07, "wra": 2.0, "wry": 40.0})
