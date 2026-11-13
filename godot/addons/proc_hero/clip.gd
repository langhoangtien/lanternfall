## Keyframed action clip (port of mkClip / sampTrack in src/25-anim.js).
## keys: [{t, e (ease), b: {bone: [x,y,z] euler}, tb: {bone: [x,y,z] translation}, root: [x,y,z]}]
## Missing bones carry over from the previous key; the clip starts and ends at `base` (normally the ready pose).
## `hit` is the normalised time of the hit frame: the animator stretches 0..hit over the windup and hit..1 over the recovery.
class_name ProcClip
extends RefCounted

var hit: float
var tracks := {}      # bone -> [[t, x, y, z, ease], ...]
var ttracks := {}      # bone -> translation track
var root := []


func _init(p_hit: float, keys: Array, base: Dictionary) -> void:
	hit = p_hit
	var bones := {}
	var tbs := {}
	for k: Dictionary in keys:
		for n in k.get("b", {}): bones[n] = 1
		for n in k.get("tb", {}): tbs[n] = 1
	var ks := keys.duplicate()
	if ks.is_empty() or ks[0].t > 0: ks.push_front({"t": 0.0, "_base": true})
	if ks[ks.size() - 1].t < 1: ks.push_back({"t": 1.0, "_base": true})
	var last := {}
	var lastT := {}
	var last_root := [0, 0, 0]
	for n in bones:
		tracks[n] = []; last[n] = base.get(n, [0, 0, 0])
	for n in tbs:
		ttracks[n] = []; lastT[n] = [0, 0, 0]
	for k: Dictionary in ks:
		var is_base: bool = k.get("_base", false)
		var e: String = k.get("e", "io")
		for n in bones:
			var v: Array = base.get(n, [0, 0, 0]) if is_base else k.get("b", {}).get(n, last[n])
			last[n] = v
			tracks[n].append([float(k.t), float(v[0]), float(v[1]), float(v[2]), e])
		for n in tbs:
			var v: Array = [0, 0, 0] if is_base else k.get("tb", {}).get(n, lastT[n])
			lastT[n] = v
			ttracks[n].append([float(k.t), float(v[0]), float(v[1]), float(v[2]), e])
		last_root = [0, 0, 0] if is_base else k.get("root", last_root)
		root.append([float(k.t), float(last_root[0]), float(last_root[1]), float(last_root[2]), e])


static func ease_k(name: String, t: float) -> float:
	match name:
		"in": return t * t * t
		"out": return 1.0 - pow(1.0 - t, 3.0)
		"lin": return t
		"snap": return 1.0 - pow(1.0 - t, 5.0)
	return t * t * (3.0 - 2.0 * t)


static func sample(tk: Array, t: float) -> Vector3:
	var n := tk.size()
	if t <= tk[0][0]: return Vector3(tk[0][1], tk[0][2], tk[0][3])
	if t >= tk[n - 1][0]: return Vector3(tk[n - 1][1], tk[n - 1][2], tk[n - 1][3])
	for i in n - 1:
		var a: Array = tk[i]
		var b: Array = tk[i + 1]
		if t <= b[0]:
			var u := ease_k(b[4], (t - a[0]) / (b[0] - a[0]))
			return Vector3(lerpf(a[1], b[1], u), lerpf(a[2], b[2], u), lerpf(a[3], b[3], u))
	return Vector3.ZERO
