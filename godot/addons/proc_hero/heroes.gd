## The six heroes: build recipes (geometry) + animation styles (poses and action clips).
## Port of src/21-heroes.js. Add your own hero by writing another build_xxx() and style_xxx() pair.
class_name ProcHeroes
extends RefCounted

const G := preload("res://addons/proc_hero/geo.gd")
const ORDER := ["warden", "reaver", "fletcher", "lamplighter", "apothecary", "rimebinder"]



## Returns {geo: ProcGeo, rig: ProcRig, hide: PackedStringArray, fx: {name: [bone, Vector3]}}
static func build(id: String, detail := 1.0, shells := true) -> Dictionary:
	match id:
		"warden": return _warden(detail, shells)
		"reaver": return _reaver(detail, shells)
		"fletcher": return _fletcher(detail, shells)
		"lamplighter": return _lamplighter(detail, shells)
		"apothecary": return _apothecary(detail, shells)
		"rimebinder": return _rimebinder(detail, shells)
	push_error("unknown hero " + id)
	return {}


static func _begin(P: Dictionary, detail: float, shells: bool) -> ProcGeo:
	return ProcGeo.new(ProcRig.human(P), detail, shells)


static func _lantern_back(g: ProcGeo) -> void:
	g.bone("back"); g.mat(HW.COL.wood, 0.85, 0, G.T_WOOD, 0.8)
	g.tube([Vector3(-0.12, 0.95, -0.17), Vector3(-0.13, 1.6, -0.2), Vector3(-0.14, 2.35, -0.22)], 0.017, {"seg": 6, "sub": 2})
	g.mat(HW.COL.iron, 0.55, 0.9, G.T_PLATE, 0.3)
	g.tube([Vector3(-0.14, 2.3, -0.22), Vector3(-0.14, 2.46, -0.2), Vector3(-0.14, 2.54, -0.08), Vector3(-0.14, 2.5, 0.04), Vector3(-0.14, 2.43, 0.07)], 0.009, {"seg": 5, "sub": 4})
	g.mat(HW.COL.leather, 0.7, 0, G.T_LEATHER, 0.4); g.bone("chest")
	g.tube([Vector3(-0.13, 1.47, -0.14), Vector3(0.02, 1.36, 0.135), Vector3(0.17, 1.12, 0.1), Vector3(0.12, 1.04, -0.13), Vector3(-0.13, 1.47, -0.14)], 0.012, {"seg": 5, "sub": 4, "flatten": 0.4})
	HW.lantern_body(g, "lanB", -0.14, 2.43, 0.07, 1.0)


# ======================================================================== WARDEN
## kettle helm, mail, tabard, heater shield, arming sword
static func _warden(detail: float, shells: bool) -> Dictionary:
	var P := {"sh": 0.205, "hp": 0.097}
	var g := _begin(P, detail, shells)
	var COL := HW.COL
	for s in [1, -1]:
		g.mat(COL.woolBrown, 0.95, 0, G.T_CLOTH, 1.6); HW.leg(g, P, s, {"y0": 0.3, "y1": 0.99, "k": 1.06, "wr": 0.05})
		g.mat(COL.leather, 0.74, 0, G.T_LEATHER, 1.8); HW.boot(g, P, s, {"top": 0.36})
		HW.poleyn(g, P, s); HW.greave(g, P, s)
	g.mat(COL.buff, 0.95, 0, G.T_QUILT, 1.3); HW.skirt(g, {"y0": 1.04, "y1": 0.6, "grow": 0.012, "flare": 0.06, "thick": 0.012})
	g.mat(COL.mail, 0.5, 0.85, G.T_MAIL, 0.8); HW.torso(g, {"grow": 0.014, "y0": 0.99, "y1": 1.5, "wr": 0.02})
	HW.skirt(g, {"y0": 1.03, "y1": 0.67, "grow": 0.022, "flare": 0.05, "thick": 0.007, "wave": 0.025, "folds": 7})
	for s in [1, -1]:
		g.mat(COL.mail, 0.5, 0.85, G.T_MAIL, 0.5); HW.arm(g, P, s, {"y0": 1.1, "y1": 1.5, "grow": 0.016, "k": 1.14, "wr": 0.05})
		g.mat(COL.buff, 0.95, 0, G.T_QUILT, 0.6); HW.arm(g, P, s, {"y0": 0.9, "y1": 1.13, "grow": 0.01, "k": 1.12, "cap1": false})
		HW.vambrace(g, P, s); HW.couter(g, P, s); HW.spaulder(g, P, s, {"s": 1.12})
		g.mat(COL.leatherDk, 0.7, 0, G.T_LEATHER, 0.5); HW.fist(g, P, s)
	for h in [[-PI / 2, PI / 2, COL.murrey], [PI / 2, PI * 1.5, COL.bone]]:
		g.mat(h[2], 0.95, 0, G.T_CLOTH, 1.2)
		HW.torso(g, {"grow": 0.027, "y0": 1.0, "y1": 1.47, "arc": Vector2(h[0], h[1]), "seg": 10, "thick": 0.004, "wr": 0.03, "wra": 5.0, "wry": 16.0, "blouse": 0.014})
	for p in [[PI / 2 - 0.95, PI / 2, COL.murrey], [PI / 2, PI / 2 + 0.95, COL.bone], [-PI / 2, -PI / 2 + 0.95, COL.murrey], [-PI / 2 - 0.95, -PI / 2, COL.bone]]:
		g.mat(p[2], 0.95, 0, G.T_CLOTH, 1.7)
		HW.skirt(g, {"y0": 1.04, "y1": 0.64, "grow": 0.03, "flare": 0.058, "arc": Vector2(p[0], p[1]), "seg": 8, "thick": 0.005, "wave": 0.035, "folds": 8})
	HW.belt(g, {"grow": 0.036}); HW.pouch(g, -0.16, 1.0, -0.1, 1.0); HW.pouch(g, -0.2, 1.0, 0.03, 0.8, COL.leatherTan); HW.scabbard(g, P, 1)
	HW.strap(g, {"side": -1, "grow": 0.034})
	HW.head(g, {}); HW.coif(g, P); HW.kettle(g)
	HW.cloak(g, P, {"hem": 0.56, "wrap": 0.22, "col": COL.wool, "flare": 0.07}); HW.cowl(g, P, {"col": COL.wool, "r": 0.03, "y": 1.475, "wide": 0.03})
	var sw := HW.sword(g, P, -1, {"len": 0.82}); HW.shield(g, P, 1)
	return {"geo": g, "rig": g.rig, "hide": PackedStringArray(), "fx": {"tip": ["wR", sw.tip], "base": ["wR", sw.base], "off": ["lFore", Vector3(P.sh + 0.2, 1.02, 0)]}}


# ======================================================================== REAVER
## broad, fur mantle, mail, odd plate, greatsword
static func _reaver(detail: float, shells: bool) -> Dictionary:
	var P := {"sh": 0.228, "hp": 0.102}
	var g := _begin(P, detail, shells)
	var COL := HW.COL
	for s in [1, -1]:
		g.mat(PNoise.C(0x2c2620), 0.95, 0, G.T_CLOTH, 1.7); HW.leg(g, P, s, {"y0": 0.3, "y1": 0.99, "k": 1.14, "wr": 0.06})
		g.mat(COL.leatherDk, 0.76, 0, G.T_LEATHER, 2.0); HW.boot(g, P, s, {"top": 0.42})
	HW.poleyn(g, P, -1, {"col": COL.iron}); HW.greave(g, P, 1, {"col": COL.iron})
	g.mat(PNoise.C(0x4d4332), 0.95, 0, G.T_QUILT, 1.4); HW.skirt(g, {"y0": 1.04, "y1": 0.66, "grow": 0.018, "flare": 0.06, "thick": 0.012})
	g.mat(COL.mail, 0.52, 0.85, G.T_MAIL, 1.0); HW.torso(g, {"grow": 0.016, "y0": 0.99, "y1": 1.5, "k": 1.1, "kz": 1.12, "wr": 0.02})
	HW.skirt(g, {"y0": 1.03, "y1": 0.74, "grow": 0.03, "flare": 0.045, "thick": 0.007, "wave": 0.03, "folds": 6})
	for s in [1, -1]:
		g.mat(COL.mail, 0.52, 0.85, G.T_MAIL, 0.6); HW.arm(g, P, s, {"y0": 1.12, "y1": 1.5, "grow": 0.018, "k": 1.32, "wr": 0.05})
		g.mat(PNoise.C(0x4d4332), 0.95, 0, G.T_QUILT, 0.6); HW.arm(g, P, s, {"y0": 0.9, "y1": 1.15, "grow": 0.01, "k": 1.26, "cap1": false})
		HW.vambrace(g, P, s, {} if s > 0 else {"col": COL.leatherDk, "metal": 0.0, "ty": G.T_LEATHER, "rough": 0.7})
		g.mat(COL.leatherDk, 0.7, 0, G.T_LEATHER, 0.5); HW.fist(g, P, s)
	HW.spaulder(g, P, 1, {"s": 1.42, "col": COL.plate}); HW.couter(g, P, 1); HW.spaulder(g, P, -1, {"s": 1.08, "col": COL.iron})
	g.mat(COL.leatherDk, 0.72, 0, G.T_LEATHER, 1.0); HW.torso(g, {"grow": 0.03, "y0": 1.02, "y1": 1.4, "k": 1.1, "kz": 1.12, "arc": Vector2(PI / 2 - 1.2, PI / 2 + 1.2), "seg": 10, "thick": 0.006, "wr": 0.03})
	HW.strap(g, {"side": 1, "grow": 0.05, "w": 0.02}); HW.strap(g, {"side": -1, "grow": 0.052, "w": 0.02})
	HW.belt(g, {"grow": 0.046, "w": 0.036}); HW.belt(g, {"grow": 0.052, "w": 0.02, "y": 0.995, "col": COL.leather})
	HW.pouch(g, 0.18, 0.99, -0.08, 1.1); HW.pouch(g, -0.19, 1.0, 0.02, 0.9, COL.leatherTan)
	g.mat(COL.fur, 1, 0, G.T_FUR, 1.3); HW.skirt(g, {"y0": 1.04, "y1": 0.6, "grow": 0.04, "flare": 0.07, "arc": Vector2(-PI / 2 - 1.3, -PI / 2 + 1.3), "seg": 12, "thick": 0.014, "wave": 0.05, "folds": 5})
	HW.head(g, {"beard": 1.0, "hair": COL.hair, "hairCap": true}); HW.skullcap(g); HW.fur_mantle(g, P, {"back": 0.34})
	var sw := HW.sword(g, P, -1, {"len": 1.24, "w": 0.034, "grip": 0.3, "guard": 0.14})
	return {"geo": g, "rig": g.rig, "hide": PackedStringArray(), "fx": {"tip": ["wR", sw.tip], "base": ["wR", sw.base]}}


# ======================================================================== FLETCHER
## lean, deep hood, patched cloak, longbow
static func _fletcher(detail: float, shells: bool) -> Dictionary:
	var P := {"sh": 0.19, "hp": 0.09}
	var g := _begin(P, detail, shells)
	var COL := HW.COL
	for s in [1, -1]:
		g.mat(PNoise.C(0x33372b), 0.95, 0, G.T_CLOTH, 1.5); HW.leg(g, P, s, {"y0": 0.3, "y1": 0.99, "k": 0.96, "wr": 0.05})
		g.mat(PNoise.C(0x4a3524), 0.78, 0, G.T_LEATHER, 1.9); HW.boot(g, P, s, {"top": 0.45})
	g.mat(PNoise.C(0x3c3a27), 0.95, 0, G.T_QUILT, 1.0); HW.torso(g, {"grow": 0.016, "y0": 0.99, "y1": 1.5, "k": 0.95, "blouse": 0.012})
	HW.skirt(g, {"y0": 1.04, "y1": 0.72, "grow": 0.018, "flare": 0.045, "thick": 0.012})
	for s in [1, -1]:
		g.mat(PNoise.C(0x3c3a27), 0.95, 0, G.T_QUILT, 0.6); HW.arm(g, P, s, {"grow": 0.013, "k": 1.0, "cap1": true})
		g.mat(COL.leather, 0.7, 0, G.T_LEATHER, 0.5); HW.fist(g, P, s)
	HW.vambrace(g, P, 1, {"col": COL.leatherDk, "metal": 0.0, "ty": G.T_LEATHER, "rough": 0.66})
	HW.belt(g, {"grow": 0.03}); HW.satchel(g, -0.17, 1.02, -0.07, -2.0, 0.85); HW.pouch(g, 0.17, 1.0, 0.04, 0.9)
	HW.strap(g, {"side": -1, "grow": 0.03}); HW.quiver(g)
	HW.head(g, {"skin": COL.skinDk}); HW.veil(g, {"col": PNoise.C(0x26251f), "top": 1.672})
	HW.cloak(g, P, {"hem": 0.46, "wrap": 0.55, "col": PNoise.C(0x2b2a21), "flare": 0.1, "fold": 0.1})
	HW.hood(g, P, {"col": PNoise.C(0x302d1e), "open": 0.62, "peak": 0.07})
	var bw := HW.bow(g, P)
	return {"geo": g, "rig": g.rig, "hide": PackedStringArray(["arw"]), "fx": {"tip": ["wL", Vector3(P.sh + 0.03, 0.835, 0)], "nock": ["str", bw.nock]}}


# ======================================================================== LAMPLIGHTER
## waxed coat, wide hat, the lantern on its hooked pole
static func _lamplighter(detail: float, shells: bool) -> Dictionary:
	var P := {"sh": 0.2, "hp": 0.095}
	P["lan"] = Vector3(P.sh + 0.03, 0.835 - 0.17, 1.45 - 0.02)
	var g := _begin(P, detail, shells)
	var COL := HW.COL
	for s in [1, -1]:
		g.mat(PNoise.C(0x2f2a24), 0.95, 0, G.T_CLOTH, 1.6); HW.leg(g, P, s, {"y0": 0.3, "y1": 0.99, "k": 1.03, "wr": 0.05})
		g.mat(COL.leatherDk, 0.76, 0, G.T_LEATHER, 2.0); HW.boot(g, P, s, {"top": 0.4})
	g.mat(PNoise.C(0x4a3f2e), 0.95, 0, G.T_CLOTH, 1.3); HW.skirt(g, {"y0": 1.04, "y1": 0.62, "grow": 0.008, "flare": 0.05, "wave": 0.03})
	g.mat(PNoise.C(0x4a3f2e), 0.95, 0, G.T_CLOTH, 0.8); HW.torso(g, {"grow": 0.01, "y0": 0.99, "y1": 1.5})
	var gap := 0.3
	g.mat(COL.waxed, 0.56, 0, G.T_LEATHER, 1.2); HW.torso(g, {"grow": 0.024, "y0": 1.0, "y1": 1.5, "arc": Vector2(PI / 2 + 0.2, PI / 2 - 0.2 + TAU), "thick": 0.006, "wr": 0.035, "wra": 4.0, "wry": 18.0})
	g.mat(COL.waxed, 0.56, 0, G.T_LEATHER, 1.8); HW.skirt(g, {"y0": 1.04, "y1": 0.34, "grow": 0.028, "flare": 0.1, "arc": Vector2(PI / 2 + gap, PI / 2 - gap + TAU), "seg": 26, "thick": 0.007, "wave": 0.045, "folds": 7})
	for s in [1, -1]:
		g.mat(COL.waxed, 0.56, 0, G.T_LEATHER, 0.8); HW.arm(g, P, s, {"grow": 0.02, "k": 1.08, "wr": 0.07, "cap1": true})
		g.mat(COL.leather, 0.7, 0, G.T_LEATHER, 0.5); HW.fist(g, P, s)
	HW.belt(g, {"grow": 0.04, "w": 0.03}); HW.satchel(g, 0.16, 1.02, -0.1, 2.2, 1.0); HW.pouch(g, -0.18, 1.0, 0.05, 1.0); HW.pouch(g, -0.12, 1.0, 0.11, 0.8, COL.leatherTan)
	HW.strap(g, {"side": 1, "grow": 0.04})
	HW.cloak(g, P, {"hem": 1.16, "wrap": 1.25, "col": PNoise.C(0x1f1c17), "flare": 0.035, "fold": 0.05, "clasp": false})
	HW.cowl(g, P, {"col": PNoise.C(0x5c4a2a), "r": 0.034, "y": 1.5, "wide": 0.0})
	HW.head(g, {"beard": 0.85, "hair": COL.hairGrey}); HW.hat(g)
	var hook := HW.staff(g, P, 1, {"z0": -1.08, "z1": 1.45, "head": "crook"})
	HW.lantern_body(g, "lan", hook.x, hook.y, hook.z, 1.0)
	return {"geo": g, "rig": g.rig, "hide": PackedStringArray(), "fx": {"lan": ["lan", hook - Vector3(0, 0.26, 0)], "tip": ["lan", hook - Vector3(0, 0.26, 0)]}}


# ======================================================================== APOTHECARY
## hooded, apron-coat, bandolier of flasks, heavy pack
static func _apothecary(detail: float, shells: bool) -> Dictionary:
	var P := {"sh": 0.195, "hp": 0.095}
	var g := _begin(P, detail, shells)
	var COL := HW.COL
	for s in [1, -1]:
		g.mat(PNoise.C(0x2d2a26), 0.95, 0, G.T_CLOTH, 1.6); HW.leg(g, P, s, {"y0": 0.3, "y1": 0.99, "wr": 0.05})
		g.mat(COL.leather, 0.76, 0, G.T_LEATHER, 2.0); HW.boot(g, P, s, {"top": 0.38})
	var coat: Color = PNoise.C(0x443d31)
	g.mat(coat, 0.95, 0, G.T_CLOTH, 0.9); HW.torso(g, {"grow": 0.016, "y0": 0.99, "y1": 1.5, "wr": 0.03, "wra": 4.0, "wry": 18.0, "blouse": 0.016})
	g.mat(coat, 0.95, 0, G.T_CLOTH, 1.7); HW.skirt(g, {"y0": 1.04, "y1": 0.4, "grow": 0.02, "flare": 0.095, "seg": 26, "thick": 0.007, "wave": 0.05, "folds": 8})
	for s in [1, -1]:
		g.mat(coat, 0.95, 0, G.T_CLOTH, 0.7); HW.arm(g, P, s, {"grow": 0.018, "k": 1.05, "wr": 0.08, "cap1": true})
		g.mat(COL.leatherDk, 0.7, 0, G.T_LEATHER, 0.6); HW.fist(g, P, s)
		HW.vambrace(g, P, s, {"col": COL.leatherDk, "metal": 0.0, "ty": G.T_LEATHER, "rough": 0.7})
	g.mat(PNoise.C(0x4a3423), 0.7, 0, G.T_LEATHER, 1.2); HW.torso(g, {"grow": 0.026, "y0": 1.0, "y1": 1.4, "arc": Vector2(PI / 2 - 1.05, PI / 2 + 1.05), "seg": 10, "thick": 0.006, "wr": 0.03})
	g.mat(PNoise.C(0x4a3423), 0.7, 0, G.T_LEATHER, 1.8); HW.skirt(g, {"y0": 1.04, "y1": 0.5, "grow": 0.034, "flare": 0.085, "arc": Vector2(PI / 2 - 0.95, PI / 2 + 0.95), "seg": 12, "thick": 0.006, "wave": 0.03, "folds": 5})
	HW.belt(g, {"grow": 0.04, "w": 0.03})
	HW.strap(g, {"side": 1, "grow": 0.042, "w": 0.024, "col": COL.leatherDk})
	var fc: Array = [PNoise.C(0x5a6a3a), PNoise.C(0x8a5a2a), PNoise.C(0x3a4a5a), PNoise.C(0x6a3a2a), PNoise.C(0x58603a)]
	for i in 5:
		var t := i / 4.0
		HW.flask(g, lerpf(0.115, -0.125, t), lerpf(1.385, 1.13, t), 0.158 - 0.02 * absf(t - 0.4), 0.82, fc[i], 0.5 if i == 1 else 0.0, HW.TW(), 0.1, 0.35)
	HW.flask(g, -0.2, 0.94, 0.04, 1.1, PNoise.C(0x7ab04a), 0.35, HW.skirtW(1.04), 0, 0.1); HW.flask(g, 0.2, 0.95, 0.02, 1.0, PNoise.C(0x5a4a3a), 0, HW.skirtW(1.04), 0, -0.1)
	HW.satchel(g, 0.15, 1.01, -0.1, 2.3, 0.9)
	HW.head(g, {"skin": COL.skinDk}); HW.veil(g, {"col": PNoise.C(0x4a4638), "top": 1.682}); HW.hood(g, P, {"col": PNoise.C(0x2e2c26), "open": 0.62, "peak": 0.03})
	HW.pack(g)
	HW.flask(g, -P.sh - 0.03, 0.84, 0.03, 1.25, PNoise.C(0xffa040), 0.7, "wR", -0.3, 0)
	return {"geo": g, "rig": g.rig, "hide": PackedStringArray(), "fx": {"tip": ["wR", Vector3(-P.sh - 0.03, 0.86, 0.03)]}}


# ======================================================================== RIMEBINDER
## layered robes, fur collar, staff headed with a pale shard
static func _rimebinder(detail: float, shells: bool) -> Dictionary:
	var P := {"sh": 0.19, "hp": 0.092}
	var g := _begin(P, detail, shells)
	var COL := HW.COL
	for s in [1, -1]:
		g.mat(PNoise.C(0x26282c), 0.95, 0, G.T_CLOTH, 1.5); HW.leg(g, P, s, {"y0": 0.3, "y1": 0.99, "k": 0.98})
		g.mat(COL.leatherDk, 0.76, 0, G.T_LEATHER, 2.0); HW.boot(g, P, s, {"top": 0.36})
	var under: Color = PNoise.C(0x3a434a)
	var over: Color = PNoise.C(0x1f2428)
	g.mat(under, 0.95, 0, G.T_CLOTH, 0.8); HW.torso(g, {"grow": 0.012, "y0": 0.99, "y1": 1.5, "k": 0.97, "blouse": 0.012})
	g.mat(under, 0.95, 0, G.T_CLOTH, 1.9); HW.skirt(g, {"y0": 1.04, "y1": 0.13, "grow": 0.014, "flare": 0.13, "seg": 30, "thick": 0.007, "wave": 0.055, "folds": 9})
	var gap := 0.42
	g.mat(over, 0.95, 0, G.T_CLOTH, 0.9); HW.torso(g, {"grow": 0.026, "y0": 1.0, "y1": 1.5, "k": 0.97, "arc": Vector2(PI / 2 + 0.25, PI / 2 - 0.25 + TAU), "thick": 0.007, "wr": 0.035, "wra": 4.0, "wry": 16.0})
	g.mat(over, 0.95, 0, G.T_CLOTH, 1.6); HW.skirt(g, {"y0": 1.04, "y1": 0.46, "grow": 0.03, "flare": 0.11, "arc": Vector2(PI / 2 + gap, PI / 2 - gap + TAU), "seg": 26, "thick": 0.009, "wave": 0.05, "folds": 7})
	# fur trim along the over-robe hem
	g.mat(COL.furGrey, 1, 0, G.T_FUR, 1.4); g.bone(HW.skirtW(1.04))
	var N := 26
	var pts := []
	for i in N + 1:
		var a := PI / 2 + gap + (TAU - 2 * gap) * i / N
		var c := cos(a)
		var s := sin(a)
		pts.append(Vector3(c * 0.292 * (1.0 + 0.04 * sin(a * 7.0)), 0.47, s * (0.228 if s > 0 else 0.262)))
	g.tube(pts, 0.024, {"seg": 6, "sub": 1})
	for s in [1, -1]:
		g.mat(over, 0.95, 0, G.T_CLOTH, 0.7); HW.bell_sleeve(g, P, s)
		g.mat(COL.woolGrey, 0.95, 0, G.T_CLOTH, 0.4); HW.arm(g, P, s, {"y0": 0.9, "y1": 1.0, "grow": 0.006, "cap1": false})
		g.mat(PNoise.C(0x33363a), 0.9, 0, G.T_CLOTH, 0.4); HW.fist(g, P, s)
	HW.belt(g, {"grow": 0.04, "w": 0.022, "col": COL.leather})
	g.bone(HW.skirtW(1.04)); g.mat(COL.rope, 0.9, 0, G.T_CLOTH, 0.6)
	for cx in [-0.1, -0.06, 0.09]:
		g.tube([Vector3(cx, 1.03, 0.15), Vector3(cx + 0.01, 0.9, 0.165), Vector3(cx, 0.78 + cx, 0.17)], 0.005, {"seg": 4, "sub": 2})
		g.tf(cx, 0.78 + cx, 0.17); g.mat(PNoise.C(0x9ac8e8), 0.3, 0, G.T_GLOW, 0.25)
		g.loft([{"y": -0.05, "rx": 0.002}, {"y": -0.02, "rx": 0.012}, {"y": 0.0, "rx": 0.004}], {"seg": 4, "sub": 1, "flat": true})
		g.mat(COL.rope, 0.9, 0, G.T_CLOTH, 0.6); g.pop()
	HW.satchel(g, -0.16, 1.01, -0.09, -2.2, 0.85, COL.leatherDk)
	HW.head(g, {"skin": COL.skinDk}); HW.veil(g, {"col": PNoise.C(0x5c6166), "top": 1.68}); HW.hood(g, P, {"col": PNoise.C(0x2a3036), "open": 0.64, "peak": 0.02})
	HW.fur_mantle(g, P, {"col": COL.furGrey, "back": 0.08})
	var tip := HW.staff(g, P, -1, {"z0": -1.1, "z1": 0.98, "head": "shard", "col": COL.woodDk})
	return {"geo": g, "rig": g.rig, "hide": PackedStringArray(), "fx": {"tip": ["wR", tip]}}


# ======================================================================== animation styles
const DOWN_POSE := {"hips": [0.35, 0, 0], "spine": [0.3, 0, 0], "chest": [0.28, 0, 0], "neck": [0.3, 0, 0], "head": [0.35, 0, 0.1], "lThigh": [-1.5, 0, 0.1], "lShin": [1.65, 0, 0], "lFoot": [-0.2, 0, 0],
	"rThigh": [-0.1, 0, -0.1], "rShin": [1.75, 0, 0], "rFoot": [0.9, 0, 0], "lUp": [-0.5, 0, 0.15], "lFore": [-0.7, 0, 0], "rUp": [-0.2, 0, -0.2], "rFore": [-0.5, 0, 0]}
const RB := {"hips": [0.06, -0.5, 0], "spine": [0.08, -0.08, 0], "chest": [0.06, 0, 0], "head": [0, 0.55, 0], "lThigh": [-0.48, 0.1, 0.08], "lShin": [0.5, 0, 0], "lFoot": [0, 0, 0],
	"rThigh": [0.2, -0.3, -0.1], "rShin": [0.3, 0, 0], "rFoot": [-0.4, 0, 0]}
const BASE_STANCE := {"hips": [0.02, 0.06, 0.04], "spine": [0.05, -0.03, -0.03], "chest": [0.03, -0.04, -0.025], "neck": [0.12, 0, 0], "head": [-0.08, 0.1, 0.02],
	"lThigh": [-0.17, 0.3, 0.075], "lShin": [0.27, 0, 0], "lFoot": [-0.1, 0, -0.05], "rThigh": [0.05, -0.22, -0.07], "rShin": [0.05, 0, 0], "rFoot": [-0.08, 0, 0.05],
	"lUp": [0.07, 0, 0.16], "rUp": [0.05, 0, -0.17], "lFore": [-0.4, 0.2, 0], "rFore": [-0.36, -0.2, 0]}


static func _over(base: Dictionary, over: Dictionary) -> Dictionary:
	var o := base.duplicate(true)
	for k in over: o[k] = over[k]
	return o


static func stance(over: Dictionary) -> Dictionary: return _over(BASE_STANCE, over)
static func rdy(over: Dictionary) -> Dictionary: return _over(RB, over)
static func clip(hit: float, keys: Array, base: Dictionary) -> ProcClip: return ProcClip.new(hit, keys, base)


## style: carry (relaxed pose), ready (combat pose), clips, swingL/R (arm swing), stride, gait {bounce, sway, lean, lift}, readyRoot
static func style(id: String) -> Dictionary:
	match id:
		"warden":
			var ready := rdy({"hips": [0.06, -0.55, 0], "head": [0, 0.6, 0], "lUp": [-0.75, 0, 0.3], "lFore": [-1.2, 0.3, 0], "rUp": [0.45, 0, -0.35], "rFore": [-1.5, 0, 0], "rHand": [-0.2, 0, 0]})
			return {"carry": stance({"lUp": [-0.18, 0, 0.16], "lFore": [-0.95, 0.25, 0], "rUp": [0.1, 0, -0.12], "rFore": [-0.32, 0, 0], "rHand": [0.5, 0, 0]}), "ready": ready, "readyRoot": -0.05,
				"swingL": 0.15, "swingR": 0.6, "stride": 0.96, "gait": {"bounce": 0.8, "sway": 1.5, "lean": 1.3, "lift": 0.9}, "clips": {
				"attack": clip(0.42, [
					{"t": 0.28, "e": "out", "b": {"hips": [0.0, -0.8, 0], "chest": [-0.12, -0.3, 0], "rUp": [-2.3, 0, -0.7], "rFore": [-1.5, 0, 0], "rHand": [-0.5, 0, 0], "lUp": [-0.5, 0, 0.5], "lFore": [-1.0, 0.3, 0]}, "root": [0, -0.02, -0.05]},
					{"t": 0.42, "e": "in", "b": {"hips": [0.12, 0.05, 0], "chest": [0.3, 0.5, 0], "rUp": [-1.15, 0, 0.5], "rFore": [-0.2, 0, 0], "rHand": [0.55, 0, 0], "lUp": [-0.2, 0, 0.5], "lFore": [-1.3, 0.3, 0], "lThigh": [-0.85, 0, 0.08], "lShin": [0.75, 0, 0], "rThigh": [0.4, 0, -0.1], "rShin": [0.25, 0, 0]}, "root": [0, -0.07, 0.3]},
					{"t": 0.6, "e": "out", "b": {"hips": [0.14, 0.2, 0], "chest": [0.36, 0.7, 0], "rUp": [-0.35, 0, 0.6], "rFore": [-0.35, 0, 0], "rHand": [0.7, 0, 0]}, "root": [0, -0.08, 0.32]}], ready),
				"bash": clip(0.45, [
					{"t": 0.25, "e": "out", "b": {"hips": [0.15, -0.3, 0], "chest": [0.12, -0.2, 0], "lUp": [0.1, 0, 0.35], "lFore": [-1.7, 0.3, 0]}, "root": [0, -0.1, -0.08]},
					{"t": 0.45, "e": "in", "b": {"hips": [0.2, -0.75, 0], "chest": [0.2, -0.25, 0], "lUp": [-1.25, 0, 0.1], "lFore": [-0.7, 0.3, 0], "lThigh": [-0.95, 0, 0.08], "lShin": [0.8, 0, 0], "rThigh": [0.5, 0, -0.1], "rShin": [0.2, 0, 0]}, "root": [0, -0.1, 0.45]},
					{"t": 0.65, "b": {"hips": [0.2, -0.7, 0]}, "root": [0, -0.1, 0.42]}], ready),
				"guard": clip(0.3, [
					{"t": 0.3, "e": "out", "b": {"hips": [0.18, -0.7, 0], "chest": [0.12, -0.1, 0], "lUp": [-1.0, 0, 0.2], "lFore": [-1.35, 0.3, 0], "rUp": [0.6, 0, -0.5], "rFore": [-1.2, 0, 0], "lThigh": [-0.7, 0, 0.1], "lShin": [0.85, 0, 0], "rThigh": [0.3, 0, -0.14], "rShin": [0.5, 0, 0]}, "root": [0, -0.14, 0]},
					{"t": 0.85, "b": {}, "root": [0, -0.14, 0]}], ready)}}
		"reaver":
			var ready := rdy({"rUp": [-0.15, 0, -0.32], "rFore": [-1.5, 0, 0], "rHand": [-0.45, 0, 0], "lUp": [-0.7, 0, -0.5], "lFore": [-1.45, 0, 0], "chest": [0.1, 0.1, 0]})
			return {"carry": stance({"rUp": [-0.38, 0, -0.2], "rFore": [-2.1, 0, 0], "rHand": [0.3, 0, 0], "lUp": [0.05, 0, 0.14], "lFore": [-0.3, 0, 0], "spine": [0.07, 0, 0]}), "ready": ready, "readyRoot": -0.04,
				"swingL": 0.9, "swingR": 0.08, "stride": 1.04, "gait": {"bounce": 1.0, "sway": 1.35, "lean": 1.2}, "clips": {
				"attack": clip(0.45, [
					{"t": 0.3, "e": "out", "b": {"hips": [0.0, -0.75, 0], "chest": [-0.1, -0.45, 0], "rUp": [-1.5, 0, -0.75], "rFore": [-1.9, 0, 0], "rHand": [-0.5, 0, 0], "lUp": [-1.7, 0, -0.35], "lFore": [-1.7, 0, 0]}, "root": [0, 0, -0.06]},
					{"t": 0.45, "e": "in", "b": {"hips": [0.14, 0.1, 0], "chest": [0.36, 0.6, 0], "rUp": [-1.0, 0, 0.5], "rFore": [-0.3, 0, 0], "rHand": [0.6, 0, 0], "lUp": [-1.0, 0, -0.9], "lFore": [-0.6, 0, 0], "lThigh": [-0.9, 0, 0.08], "lShin": [0.8, 0, 0], "rThigh": [0.45, 0, -0.1], "rShin": [0.25, 0, 0]}, "root": [0, -0.09, 0.36]},
					{"t": 0.66, "e": "out", "b": {"chest": [0.42, 0.8, 0], "rUp": [-0.4, 0, 0.6], "rHand": [0.8, 0, 0], "lUp": [-0.5, 0, -0.9]}, "root": [0, -0.1, 0.38]}], ready),
				"cleave": clip(0.5, [
					{"t": 0.32, "e": "out", "b": {"hips": [0.05, -1.0, 0], "spine": [0.05, -0.3, 0], "chest": [0.0, -0.5, 0], "rUp": [-1.3, 0, -1.1], "rFore": [-0.9, 0, 0], "rHand": [0.1, 0.4, 0], "lUp": [-1.5, 0, -0.5], "lFore": [-1.2, 0, 0]}, "root": [0, -0.06, -0.08]},
					{"t": 0.5, "e": "in", "b": {"hips": [0.1, 0.3, 0], "spine": [0.1, 0.3, 0], "chest": [0.15, 0.6, 0], "rUp": [-1.35, 0, 0.35], "rFore": [-0.25, 0, 0], "rHand": [0.2, -0.2, 0], "lUp": [-1.3, 0, -0.9], "lFore": [-0.5, 0, 0], "lThigh": [-0.8, 0, 0.1], "lShin": [0.75, 0, 0], "rThigh": [0.4, 0, -0.12], "rShin": [0.3, 0, 0]}, "root": [0, -0.1, 0.3]},
					{"t": 0.7, "e": "out", "b": {"hips": [0.1, 0.6, 0], "chest": [0.15, 0.9, 0], "rUp": [-1.2, 0, 0.9]}, "root": [0, -0.1, 0.3]}], ready),
				"sunder": clip(0.56, [
					{"t": 0.36, "e": "out", "b": {"hips": [-0.1, -0.2, 0], "spine": [-0.18, 0, 0], "chest": [-0.25, 0, 0], "rUp": [-2.85, 0, -0.25], "rFore": [-0.9, 0, 0], "rHand": [-0.9, 0, 0], "lUp": [-2.85, 0, -0.4], "lFore": [-1.0, 0, 0], "head": [-0.2, 0.3, 0]}, "root": [0, 0.03, -0.05]},
					{"t": 0.56, "e": "in", "b": {"hips": [0.32, -0.2, 0], "spine": [0.3, 0, 0], "chest": [0.4, 0, 0], "rUp": [-1.0, 0, 0.1], "rFore": [-0.15, 0, 0], "rHand": [0.95, 0, 0], "lUp": [-1.0, 0, -0.55], "lFore": [-0.3, 0, 0], "lThigh": [-1.0, 0, 0.1], "lShin": [1.0, 0, 0], "rThigh": [0.3, 0, -0.12], "rShin": [0.7, 0, 0], "head": [0.1, 0.3, 0]}, "root": [0, -0.22, 0.38]},
					{"t": 0.74, "b": {}, "root": [0, -0.22, 0.38]}], ready)}}
		"fletcher":
			var ready := rdy({"hips": [0.04, -0.85, 0], "chest": [0.04, -0.15, 0], "neck": [0.05, 0.35, 0], "head": [0, 0.6, 0], "lUp": [0, 1.1, 0.75], "lFore": [-0.25, 0, 0], "rUp": [-0.5, 0, -0.25], "rFore": [-1.7, 0, 0], "lThigh": [-0.3, 0.3, 0.12], "rThigh": [0.12, -0.2, -0.1]})
			var drawn := {"hips": [0.0, -1.15, 0], "spine": [-0.04, -0.2, 0], "chest": [-0.04, -0.2, 0], "neck": [0, 0.5, 0], "head": [0, 0.95, 0], "lUp": [0, 1.57, 1.52], "lFore": [-0.08, 0, 0], "rUp": [0, 1.2, -1.5], "rFore": [-2.45, 0, 0], "rHand": [0, 0, 0]}
			var shoot := func(pitch: float) -> ProcClip:
				return clip(0.6, [
					{"t": 0.22, "e": "out", "b": {"hips": [0, -1.1, 0], "spine": [0, -0.2, 0], "chest": [0, -0.2, 0], "neck": [0, 0.5, 0], "head": [0, 0.9, 0], "lUp": [0, 1.57, 1.3 + pitch], "lFore": [-0.15, 0, 0], "rUp": [0, 1.2, -1.2 - pitch * 0.3], "rFore": [-1.5, 0, 0]}, "tb": {"str": [0, 0.05, 0]}},
					{"t": 0.5, "e": "io", "b": _over(drawn, {"lUp": [0, 1.57, 1.52 + pitch], "spine": [-0.04, -0.2, pitch * 0.4]}), "tb": {"str": [0, 0.5, 0]}},
					{"t": 0.6, "e": "lin", "b": {}, "tb": {"str": [0, 0.52, 0]}},
					{"t": 0.63, "e": "snap", "b": {"rUp": [0, 1.2, -1.75], "rFore": [-2.1, 0, 0]}, "tb": {"str": [0, 0, 0]}},
					{"t": 0.8, "b": {}, "tb": {"str": [0, 0, 0]}}], ready)
			var a: ProcClip = shoot.call(0.0)
			return {"carry": stance({"lUp": [0.06, 0, 0.14], "lFore": [-0.4, 0.3, 0], "rUp": [0.03, 0, -0.1], "rFore": [-0.25, 0, 0]}), "ready": ready, "readyRoot": -0.02,
				"swingL": 0.35, "swingR": 1.0, "stride": 1.02, "gait": {"bounce": 1.35, "sway": 0.6, "lean": 0.8, "lift": 1.5},
				"clips": {"attack": a, "aimed": a, "volley": shoot.call(0.45)}, "arrow_bone": "arw"}
		"lamplighter":
			var ready := rdy({"hips": [0.05, -0.3, 0], "head": [0, 0.3, 0], "lUp": [-0.45, 0, 0.18], "lFore": [-1.25, 0, 0], "rUp": [-0.5, 0, -0.3], "rFore": [-1.1, 0, 0]})
			var kindle := clip(0.5, [
				{"t": 0.25, "e": "out", "b": {"spine": [0.15, 0, 0], "chest": [0.15, 0, 0], "lUp": [-0.5, 0, 0.2], "lFore": [-1.6, 0, 0], "rUp": [-0.5, 0, -0.2], "rFore": [-1.6, 0, 0]}, "root": [0, -0.08, 0]},
				{"t": 0.5, "e": "out", "b": {"hips": [-0.05, -0.1, 0], "spine": [-0.1, 0, 0], "chest": [-0.15, 0, 0], "head": [-0.3, 0.1, 0], "lUp": [-2.1, 0, 0.2], "lFore": [-0.85, 0, 0], "rUp": [-2.0, 0, -0.5], "rFore": [-0.6, 0, 0]}, "root": [0, 0.02, 0]},
				{"t": 0.78, "b": {}, "root": [0, 0.02, 0]}], ready)
			return {"carry": stance({"lUp": [-0.1, 0, 0.1], "lFore": [-1.42, 0, 0], "rUp": [0.03, 0, -0.1], "rFore": [-0.25, 0, 0]}), "ready": ready, "readyRoot": -0.03,
				"swingL": 0.04, "swingR": 0.95, "gait": {"bounce": 0.9, "sway": 1.1, "lean": 1.4}, "clips": {
				"attack": clip(0.5, [
					{"t": 0.3, "e": "out", "b": {"chest": [-0.1, 0.3, 0], "lUp": [-0.3, 0, 0.3], "lFore": [-1.7, 0, 0], "lHand": [-0.55, 0, 0], "rUp": [-1.5, 0, -0.35], "rFore": [-0.9, 0, 0], "hips": [0.0, 0.1, 0]}, "root": [0, -0.02, -0.05]},
					{"t": 0.5, "e": "in", "b": {"hips": [0.12, -0.5, 0], "chest": [0.26, -0.3, 0], "lUp": [-0.95, 0, 0.12], "lFore": [-0.85, 0, 0], "lHand": [1.0, 0, 0], "rUp": [-1.45, 0, 0.1], "rFore": [-0.15, 0, 0], "lThigh": [-0.75, 0.1, 0.08], "lShin": [0.7, 0, 0]}, "root": [0, -0.07, 0.2]},
					{"t": 0.7, "b": {}, "root": [0, -0.07, 0.2]}], ready),
				"kindle": kindle, "cinder": kindle}}
		"apothecary":
			var ready := rdy({"hips": [0.05, -0.3, 0], "head": [0, 0.3, 0], "lUp": [-0.3, 0, 0.25], "lFore": [-0.9, 0, 0], "rUp": [-0.3, 0, -0.3], "rFore": [-1.5, 0, 0]})
			var atk := clip(0.5, [
				{"t": 0.3, "e": "out", "b": {"hips": [0, -0.7, 0], "chest": [-0.15, -0.4, 0], "rUp": [-2.5, 0, -0.6], "rFore": [-1.6, 0, 0], "lUp": [-0.9, 0, 0.2], "lFore": [-0.5, 0, 0]}, "root": [0, 0, -0.06]},
				{"t": 0.5, "e": "in", "b": {"hips": [0.12, 0.1, 0], "chest": [0.32, 0.5, 0], "rUp": [-1.5, 0, 0.15], "rFore": [-0.15, 0, 0], "lUp": [0.2, 0, 0.3], "lThigh": [-0.8, 0.1, 0.08], "lShin": [0.7, 0, 0]}, "root": [0, -0.08, 0.22]},
				{"t": 0.7, "e": "out", "b": {"rUp": [-0.5, 0, 0.3], "chest": [0.36, 0.6, 0]}, "root": [0, -0.08, 0.22]}], ready)
			var tonic := clip(0.5, [
				{"t": 0.28, "e": "out", "b": {"chest": [0.1, -0.3, 0], "rUp": [0.6, 0, -0.25], "rFore": [-0.5, 0, 0]}, "root": [0, -0.06, 0]},
				{"t": 0.5, "e": "in", "b": {"chest": [-0.05, 0.3, 0], "rUp": [-1.7, 0, -0.1], "rFore": [-0.4, 0, 0]}, "root": [0, 0, 0.08]},
				{"t": 0.7, "b": {}, "root": [0, 0, 0.08]}], ready)
			return {"carry": stance({"lUp": [0.03, 0, 0.1], "lFore": [-0.5, 0, 0], "rUp": [-0.1, 0, -0.1], "rFore": [-0.85, 0, 0], "spine": [0.1, 0, 0]}), "ready": ready, "readyRoot": -0.03,
				"swingL": 0.9, "swingR": 0.35, "stride": 0.92, "gait": {"bounce": 1.1, "sway": 1.2, "lean": 1.6},
				"clips": {"attack": atk, "firepot": atk, "tonic": tonic, "quick": tonic}}
		"rimebinder":
			var ready := rdy({"hips": [0.04, 0.3, 0], "head": [0, -0.3, 0], "lThigh": [0.15, 0.2, 0.1], "lShin": [0.3, 0, 0], "rThigh": [-0.4, -0.1, -0.08], "rShin": [0.45, 0, 0], "rFoot": [0, 0, 0], "lFoot": [-0.35, 0, 0], "rUp": [-0.45, 0, -0.15], "rFore": [-1.2, 0, 0], "rHand": [0.25, 0, 0], "lUp": [-0.5, 0, 0.3], "lFore": [-1.0, 0, 0]})
			var hoar := clip(0.52, [
				{"t": 0.32, "e": "out", "b": {"spine": [-0.12, 0, 0], "chest": [-0.15, 0, 0], "rUp": [-1.3, 0, -0.2], "rFore": [-1.5, 0, 0], "lUp": [-1.5, 0, 0.3], "lFore": [-1.2, 0, 0], "head": [-0.2, -0.3, 0]}, "root": [0, 0.03, 0]},
				{"t": 0.52, "e": "in", "b": {"spine": [0.22, 0, 0], "chest": [0.22, 0, 0], "rUp": [-0.5, 0, -0.15], "rFore": [-1.1, 0, 0], "lUp": [-0.6, 0, 0.5], "lFore": [-0.6, 0, 0], "lShin": [0.6, 0, 0], "rShin": [0.8, 0, 0], "lThigh": [0.0, 0.2, 0.1], "rThigh": [-0.6, -0.1, -0.08]}, "root": [0, -0.16, 0.05]},
				{"t": 0.75, "b": {}, "root": [0, -0.16, 0.05]}], ready)
			return {"carry": stance({"rUp": [-0.1, 0, -0.1], "rFore": [-1.42, 0, 0], "lUp": [0.03, 0, 0.1], "lFore": [-0.3, 0, 0]}), "ready": ready, "readyRoot": -0.03,
				"swingL": 0.9, "swingR": 0.04, "stride": 0.9, "gait": {"bounce": 0.7, "sway": 0.8, "lean": 0.9}, "clips": {
				"attack": clip(0.5, [
					{"t": 0.3, "e": "out", "b": {"chest": [-0.1, -0.3, 0], "rUp": [-2.3, 0, -0.3], "rFore": [-0.7, 0, 0], "rHand": [-0.35, 0, 0], "lUp": [-1.9, 0, -0.2], "lFore": [-0.9, 0, 0], "spine": [-0.12, 0, 0]}, "root": [0, -0.02, -0.05]},
					{"t": 0.5, "e": "in", "b": {"hips": [0.1, 0.5, 0], "chest": [0.22, 0.3, 0], "rUp": [-1.45, 0, 0.05], "rFore": [-0.25, 0, 0], "rHand": [1.35, 0, 0], "lUp": [-1.25, 0, -0.45], "lFore": [-0.7, 0, 0], "spine": [0.2, 0, 0]}, "root": [0, -0.06, 0.18]},
					{"t": 0.72, "b": {}, "root": [0, -0.06, 0.18]}], ready),
				"hoar": hoar, "shatter": hoar}}
	return {}
