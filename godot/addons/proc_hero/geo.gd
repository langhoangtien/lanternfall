## ProcGeo: procedural mesh builder with two-bone skin weights.
## Port of the LANTERNFALL "kit" (src/10-kit.js) to Godot 4.
##
## Coordinates: Y up, the figure faces +Z, 1 unit = 1 metre. The bind pose has
## the limbs hanging along -Y and every bone rotation at identity.
##
## Per-vertex data written to the ArrayMesh:
##   COLOR   base colour (linear)
##   UV      surface uv in metres (for the procedural textures)
##   CUSTOM0 (roughness, metalness, surface type, grime)
##   CUSTOM1 rest position (xyz) so textures stick to the skin while animating
##   BONES / WEIGHTS  two bones per vertex
class_name ProcGeo
extends RefCounted

const TAU_ := TAU

# surface types (match surf.gdshader)
const T_SKIN := 0
const T_CLOTH := 1
const T_QUILT := 2
const T_MAIL := 3
const T_LEATHER := 4
const T_PLATE := 5
const T_FUR := 6
const T_WOOD := 7
const T_STONE := 8
const T_PEAT := 9
const T_GLOW := 10
const T_BONE := 11

var rig: ProcRig
## 1.0 = desktop quality. Lower values reduce segment counts (0.5 is a good phone setting).
var detail := 1.0
## When false, "thick" shells (cloth with a back face and rims) are built as a single surface.
## Saves roughly a third of the triangles; the shader draws both sides anyway.
var shells := true

var P := PackedVector3Array()
var N := PackedVector3Array()
var Cc := PackedColorArray()
var UV := PackedVector2Array()
var M := PackedFloat32Array()   # 4 per vertex
var BA := PackedInt32Array()
var BB := PackedInt32Array()
var W := PackedFloat32Array()
var I := PackedInt32Array()

var m_col := Color(0.5, 0.5, 0.5)
var m_r := 0.8
var m_me := 0.0
var m_ty := 0
var m_g := 1.0
var bn: Variant = 0           # bone name, bone index, or Callable(Vector3) -> [a, b, w]
var xf := Transform3D.IDENTITY
var stack: Array[Transform3D] = []


func _init(p_rig: ProcRig = null, p_detail := 1.0, p_shells := true) -> void:
	rig = p_rig
	detail = p_detail
	shells = p_shells


# ---------------------------------------------------------------- state
func mat(c: Color, r: float, me := 0.0, ty := 0, g := 1.0) -> ProcGeo:
	m_col = c; m_r = r; m_me = me; m_ty = ty; m_g = g
	return self


func save_mat() -> Array:
	return [m_col, m_r, m_me, m_ty, m_g]


func load_mat(s: Array) -> void:
	m_col = s[0]; m_r = s[1]; m_me = s[2]; m_ty = s[3]; m_g = s[4]


func bone(b: Variant) -> ProcGeo:
	bn = b
	return self


func _bi(b: Variant) -> int:
	if b is int:
		return b
	return rig.index(b)


func push(t: Transform3D) -> ProcGeo:
	stack.append(xf)
	xf = xf * t
	return self


## translate, rotate (Euler YXZ like three.js), scale; then push. Pair with pop().
func tf(x := 0.0, y := 0.0, z := 0.0, rx := 0.0, ry := 0.0, rz := 0.0, sx := 1.0, sy := NAN, sz := NAN) -> ProcGeo:
	if is_nan(sy): sy = sx
	if is_nan(sz): sz = sx
	var b := Basis.from_euler(Vector3(rx, ry, rz), EULER_ORDER_YXZ)
	b.x *= sx; b.y *= sy; b.z *= sz
	return push(Transform3D(b, Vector3(x, y, z)))


func pop() -> ProcGeo:
	xf = stack.pop_back()
	return self


# ---------------------------------------------------------------- detail scaling
func _seg(n: int, lo := 3) -> int:
	if detail >= 0.999 or n <= lo:
		return n
	return maxi(lo, int(round(n * detail)))


func _sub(n: int) -> int:
	if detail >= 0.999 or n <= 1:
		return n
	return maxi(1, int(round(n * detail)))


# ---------------------------------------------------------------- emit
func _emit(p: Vector3, n: Vector3, u: float, v: float) -> int:
	var i := P.size()
	P.append(p); N.append(n); Cc.append(m_col); UV.append(Vector2(u, v))
	M.append(m_r); M.append(m_me); M.append(float(m_ty)); M.append(m_g)
	if rig:
		if bn is Callable:
			var r: Array = (bn as Callable).call(p)
			BA.append(_bi(r[0])); BB.append(_bi(r[1])); W.append(clampf(r[2], 0.0, 1.0))
		else:
			var k := _bi(bn)
			BA.append(k); BB.append(k); W.append(0.0)
	return i


func _tri(a: int, b: int, c: int) -> void:
	I.append(a); I.append(b); I.append(c)


# ---------------------------------------------------------------- surfaces
## Parametric surface. fn(u, v) -> Vector3 in local space.
## opt: closeU, flip, flat, uv (Vector2 lengths), cap0, cap1, thick
func surf(nu: int, nv: int, fn: Callable, opt := {}) -> ProcGeo:
	var cu: bool = opt.get("closeU", false)
	var Wd := nu + 1
	var Hd := nv + 1
	var G := PackedVector3Array()
	G.resize(Wd * Hd)
	var cen := Vector3.ZERO
	for j in Hd:
		for i in Wd:
			var uu := 0.0 if (cu and i == nu) else float(i) / nu
			var p: Vector3 = xf * (fn.call(uu, float(j) / nv) as Vector3)
			G[j * Wd + i] = p
			cen += p
	cen /= float(Wd * Hd)
	var det := xf.basis.determinant() < 0.0
	var flip: bool = bool(opt.get("flip", false)) != det
	var uL := 0.0
	var vL := 0.0
	if opt.has("uv"):
		uL = opt.uv.x; vL = opt.uv.y
	else:
		var jm := Hd >> 1
		var im := Wd >> 1
		for i in nu:
			uL += G[jm * Wd + i].distance_to(G[jm * Wd + i + 1])
		for j in nv:
			vL += G[j * Wd + im].distance_to(G[(j + 1) * Wd + im])
	# smooth normals from the grid
	var NN := PackedVector3Array()
	NN.resize(Wd * Hd)
	for j in Hd:
		for i in Wd:
			var i0 := i - 1
			var i1 := i + 1
			if cu:
				if i0 < 0: i0 = nu - 1
				if i1 > nu: i1 = 1
			else:
				i0 = maxi(i0, 0); i1 = mini(i1, nu)
			var j0 := maxi(0, j - 1)
			var j1 := mini(nv, j + 1)
			var du := G[j * Wd + i1] - G[j * Wd + i0]
			var dv := G[j1 * Wd + i] - G[j0 * Wd + i]
			var n := dv.cross(du)
			var l := n.length()
			var k := j * Wd + i
			if l < 1e-9:
				n = G[k] - cen
				l = n.length()
				if l == 0.0: l = 1.0
				NN[k] = n / l          # degenerate (poles): point away from the centre
			else:
				NN[k] = n / (-l if flip else l)
	var th: float = opt.get("thick", 0.0)
	if not shells:
		th = 0.0
	var flat: bool = opt.get("flat", false)
	if flat:
		for j in nv:
			for i in nu:
				var ia := j * Wd + i
				var ib := ia + Wd
				var ic := ia + 1
				var id := ib + 1
				var du := G[ic] - G[ia]
				var dv := G[ib] - G[ia]
				var n := dv.cross(du)
				var l := n.length()
				if l < 1e-12:
					var dw := G[id] - G[ib]
					n = dv.cross(dw)
					l = n.length()
					if l == 0.0: l = 1.0
				if flip: l = -l
				n /= l
				var a := _emit(G[ia], n, float(i) / nu * uL, float(j) / nv * vL)
				var b := _emit(G[ib], n, float(i) / nu * uL, float(j + 1) / nv * vL)
				var c := _emit(G[ic], n, float(i + 1) / nu * uL, float(j) / nv * vL)
				var d := _emit(G[id], n, float(i + 1) / nu * uL, float(j + 1) / nv * vL)
				if flip:
					_tri(a, c, b); _tri(c, d, b)
				else:
					_tri(a, b, c); _tri(c, b, d)
	else:
		_emit_grid(G, NN, Wd, Hd, nu, nv, uL, vL, 0.0, false, flip)
		if th > 0.0:
			_emit_grid(G, NN, Wd, Hd, nu, nv, uL, vL, th, true, flip)
			var r0 := PackedInt32Array()
			var r1 := PackedInt32Array()
			var c0 := PackedInt32Array()
			var c1 := PackedInt32Array()
			for i in Wd:
				r0.append(i); r1.append(nv * Wd + i)
			for j in Hd:
				c0.append(j * Wd); c1.append(j * Wd + nu)
			if not opt.get("cap0", false):
				var inn := PackedInt32Array()
				for q in Wd: inn.append(Wd + q)
				_rim(G, NN, r0, inn, th, uL)
			if not opt.get("cap1", false):
				var inn := PackedInt32Array()
				for q in Wd: inn.append((nv - 1) * Wd + q)
				_rim(G, NN, r1, inn, th, uL)
			if not cu:
				var inn0 := PackedInt32Array()
				var inn1 := PackedInt32Array()
				for q in Hd:
					inn0.append(q * Wd + 1); inn1.append(q * Wd + nu - 1)
				_rim(G, NN, c0, inn0, th, uL)
				_rim(G, NN, c1, inn1, th, uL)
	if cu:
		if opt.get("cap0", false): _cap(G, Wd, nu, nv, 0)
		if opt.get("cap1", false): _cap(G, Wd, nu, nv, nv)
	return self


func _emit_grid(G: PackedVector3Array, NN: PackedVector3Array, Wd: int, Hd: int, nu: int, nv: int, uL: float, vL: float, off: float, inv: bool, flip: bool) -> void:
	var base := P.size()
	var s := -1.0 if inv else 1.0
	for j in Hd:
		for i in Wd:
			var k := j * Wd + i
			_emit(G[k] - NN[k] * off, NN[k] * s, float(i) / nu * uL, float(j) / nv * vL)
	var f := flip != inv
	for j in nv:
		for i in nu:
			var a := base + j * Wd + i
			var b := a + Wd
			var c := a + 1
			var d := b + 1
			if f:
				_tri(a, c, b); _tri(c, d, b)
			else:
				_tri(a, b, c); _tri(c, b, d)


func _rim(G: PackedVector3Array, NN: PackedVector3Array, idx: PackedInt32Array, inner: PackedInt32Array, th: float, uL: float) -> void:
	var base := P.size()
	var n := idx.size()
	for q in n:
		var k := idx[q]
		var nn := (G[k] - G[inner[q]])
		var l := nn.length()
		nn = nn / (l if l > 0.0 else 1.0)
		_emit(G[k], nn, float(q) / n * uL, 0.0)
		_emit(G[k] - NN[k] * th, nn, float(q) / n * uL, th)
	for q in n - 1:
		var a := base + q * 2
		_tri(a, a + 1, a + 2); _tri(a + 2, a + 1, a + 3)
		_tri(a, a + 2, a + 1); _tri(a + 2, a + 3, a + 1)


func _cap(G: PackedVector3Array, Wd: int, nu: int, nv: int, j: int) -> void:
	var c := Vector3.ZERO
	for i in nu:
		c += G[j * Wd + i]
	c /= float(nu)
	var n := Vector3.ZERO  # Newell
	for i in nu:
		var a := G[j * Wd + i]
		var b := G[j * Wd + (i + 1) % nu]
		n.x += (a.y - b.y) * (a.z + b.z)
		n.y += (a.z - b.z) * (a.x + b.x)
		n.z += (a.x - b.x) * (a.y + b.y)
	var l := n.length()
	n /= (l if l > 0.0 else 1.0)
	var jn := 1 if j == 0 else nv - 1
	var dd := G[j * Wd] - G[jn * Wd]
	var s := 1
	if n.dot(dd) < 0.0:
		n = -n; s = -1
	var ci := _emit(c, n, 0.0, 0.0)
	var b0 := P.size()
	for i in nu:
		var p := G[j * Wd + i]
		_emit(p, n, p.x - c.x, p.z - c.z)
	for i in nu:
		var a := b0 + i
		var b := b0 + (i + 1) % nu
		if s > 0: _tri(ci, a, b)
		else: _tri(ci, b, a)


static func catmull(a: float, b: float, c: float, d: float, t: float) -> float:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * b) + (-a + c) * t + (2.0 * a - 5.0 * b + 4.0 * c - d) * t2 + (-a + 3.0 * b - 3.0 * c + d) * t3)


static func spow(v: float, e: float) -> float:
	return -pow(-v, e) if v < 0.0 else pow(v, e)


## Loft through horizontal rings (the main tool). Each ring is a Dictionary:
##   y, rx (half width), rz (front depth), rb (back depth), x, z (centre offset), sq (2 = ellipse, higher = squarer)
## opt: seg, sub, arc (Vector2 radians, 0 = +X, PI/2 = +Z/front), cap0, cap1, thick, flat,
##      wr (wrinkle amount), wra, wry (wrinkle frequency around / along)
func loft(rings: Array, opt := {}) -> ProcGeo:
	var seg := _seg(int(opt.get("seg", 12)), 4 if opt.get("flat", false) else 3)
	var sub := _sub(int(opt.get("sub", 3)))
	var nr := rings.size()
	var R: Array[PackedFloat32Array] = []
	for r: Dictionary in rings:
		var rx: float = r.get("rx", 0.0)
		var rz: float = r.get("rz", rx)
		var rb: float = r.get("rb", rz)
		R.append(PackedFloat32Array([r.y, rx, rz, rb, r.get("x", 0.0), r.get("z", 0.0), r.get("sq", 2.0)]))
	var nv := (nr - 1) * sub
	var has_arc := opt.has("arc")
	var a0 := 0.0
	var a1 := TAU
	if has_arc:
		a0 = opt.arc.x; a1 = opt.arc.y
	var o := opt.duplicate()
	o["closeU"] = not has_arc
	var wr: float = opt.get("wr", 0.0)
	var wra: float = opt.get("wra", 3.0)
	var wry: float = opt.get("wry", 30.0)
	var wo := float((P.size() * 3) % 977) * 0.37
	var fn := func(u: float, v: float) -> Vector3:
		var tmp := PackedFloat32Array()
		tmp.resize(7)
		var f := v * (nr - 1)
		var i := mini(nr - 2, int(floor(f)))
		f -= i
		var A := R[maxi(0, i - 1)]
		var B := R[i]
		var Cq := R[i + 1]
		var D := R[mini(nr - 1, i + 2)]
		for k in 7:
			tmp[k] = lerpf(B[k], Cq[k], f) if sub == 1 else catmull(A[k], B[k], Cq[k], D[k], f)
		var a := a0 + (a1 - a0) * u
		var c := cos(a)
		var s := sin(a)
		var e := 2.0 / maxf(0.5, tmp[6])
		var kk := 1.0
		if wr != 0.0:
			var ww := a if has_arc else (TAU - a if u > 0.5 else a)
			kk = 1.0 + wr * (PNoise.vnoise2(ww * wra + wo, tmp[0] * wry + wo) + 0.5 * PNoise.vnoise2(ww * wra * 2.3 + wo, tmp[0] * wry * 2.1) - 0.75) * 1.4
		var rr := tmp[2] if s >= 0.0 else tmp[3]
		return Vector3(tmp[4] + maxf(0.0, tmp[1]) * kk * spow(c, e), tmp[0], tmp[5] + maxf(0.0, rr) * kk * spow(s, e))
	return surf(seg, nv, fn, o)


## profile: Array of Vector2(radius, y)
func lathe(prof: Array, seg := 12, opt := {}) -> ProcGeo:
	var rings := []
	for p: Vector2 in prof:
		rings.append({"y": p.y, "rx": p.x})
	var o := opt.duplicate()
	o["seg"] = seg
	if not o.has("sub"): o["sub"] = 1
	return loft(rings, o)


func sphere(r: float, sy := NAN, sz := NAN, nu := 12, nv := 8) -> ProcGeo:
	if is_nan(sy): sy = r
	if is_nan(sz): sz = r
	return surf(_seg(nu, 4), _seg(nv, 3), func(u: float, v: float) -> Vector3:
		var a := u * TAU
		var b := (v - 0.5) * PI
		var cb := cos(b)
		return Vector3(r * cos(a) * cb, sy * sin(b), sz * sin(a) * cb), {"closeU": true})


func box(w: float, h: float, d: float, sq := 16.0) -> ProcGeo:
	return loft([{"y": 0.0, "rx": w / 2, "rz": d / 2, "sq": sq}, {"y": h, "rx": w / 2, "rz": d / 2, "sq": sq}], {"seg": 8, "sub": 1, "cap0": true, "cap1": true})


## Sweep a round (or flattened) section along a Catmull-Rom path.
## pts: Array of Vector3; rad: float or Callable(t 0..1) -> float
## opt: seg, sub, flatten, up (Vector3), cap (default true), flat
func tube(pts: Array, rad: Variant, opt := {}) -> ProcGeo:
	var seg := _seg(int(opt.get("seg", 7)), 3)
	var sub := _sub(int(opt.get("sub", 3)))
	var n := pts.size()
	var nv := n - 1 if sub == 1 else (n - 1) * sub
	var rf: Callable = rad if rad is Callable else func(_t: float) -> float: return rad
	var flat: float = opt.get("flatten", 1.0)
	var Pp: Array[Vector3] = []
	for j in nv + 1:
		var f := float(j) / nv * (n - 1)
		var i := mini(n - 2, int(floor(f)))
		f -= i
		var A: Vector3 = pts[maxi(0, i - 1)]
		var B: Vector3 = pts[i]
		var Cq: Vector3 = pts[i + 1]
		var D: Vector3 = pts[mini(n - 1, i + 2)]
		Pp.append(Vector3(catmull(A.x, B.x, Cq.x, D.x, f), catmull(A.y, B.y, Cq.y, D.y, f), catmull(A.z, B.z, Cq.z, D.z, f)))
	var T: Array[Vector3] = []
	for j in nv + 1:
		T.append((Pp[mini(nv, j + 1)] - Pp[maxi(0, j - 1)]).normalized())
	var U: Array[Vector3] = []
	var V: Array[Vector3] = []
	var u0 := Vector3(1, 0, 0)
	if absf(T[0].x) > 0.9: u0 = Vector3(0, 0, 1)
	if opt.has("up"): u0 = opt.up
	u0 = (u0 - T[0] * u0.dot(T[0])).normalized()
	for j in nv + 1:
		if j > 0:
			u0 = (u0 - T[j] * u0.dot(T[j])).normalized()
		U.append(u0)
		V.append(T[j].cross(u0))
	var cap: bool = opt.get("cap", true)
	return surf(seg, nv, func(u: float, v: float) -> Vector3:
		var j := int(round(v * nv))
		var a := u * TAU
		var r: float = rf.call(float(j) / nv)
		var c := cos(a) * r
		var s := sin(a) * r * flat
		return Pp[j] + U[j] * c + V[j] * s, {"closeU": true, "cap0": cap, "cap1": cap, "flat": opt.get("flat", false)})


# ---------------------------------------------------------------- output
func tri_count() -> int:
	return I.size() / 3


## Build the ArrayMesh. Godot treats clockwise triangles as front faces, so every triangle is reversed here.
func to_mesh(material: Material = null) -> ArrayMesh:
	var nvtx := P.size()
	var idx := PackedInt32Array()
	idx.resize(I.size())
	for t in range(0, I.size(), 3):
		idx[t] = I[t]; idx[t + 1] = I[t + 2]; idx[t + 2] = I[t + 1]
	var c0 := PackedFloat32Array()
	c0.resize(nvtx * 4)
	var c1 := PackedFloat32Array()
	c1.resize(nvtx * 4)
	for i in nvtx:
		for k in 4:
			c0[i * 4 + k] = M[i * 4 + k]
		c1[i * 4] = P[i].x; c1[i * 4 + 1] = P[i].y; c1[i * 4 + 2] = P[i].z; c1[i * 4 + 3] = 0.0
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = P
	arr[Mesh.ARRAY_NORMAL] = N
	arr[Mesh.ARRAY_COLOR] = Cc
	arr[Mesh.ARRAY_TEX_UV] = UV
	arr[Mesh.ARRAY_CUSTOM0] = c0
	arr[Mesh.ARRAY_CUSTOM1] = c1
	arr[Mesh.ARRAY_INDEX] = idx
	var flags := (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) | (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT)
	if rig:
		var bones := PackedInt32Array()
		bones.resize(nvtx * 4)
		var wts := PackedFloat32Array()
		wts.resize(nvtx * 4)
		for i in nvtx:
			var w := W[i]
			bones[i * 4] = BA[i]; bones[i * 4 + 1] = BB[i]
			wts[i * 4] = 1.0 - w; wts[i * 4 + 1] = w
		arr[Mesh.ARRAY_BONES] = bones
		arr[Mesh.ARRAY_WEIGHTS] = wts
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, flags)
	if material:
		mesh.surface_set_material(0, material)
	return mesh


# ---------------------------------------------------------------- skin-weight helpers
## Blend from bone a (above y0) to bone b (below y0) across +-range.
static func jb(a: String, b: String, y0: float, range_: float) -> Callable:
	return func(p: Vector3) -> Array:
		return [a, b, 1.0 - PNoise.smooth(y0 - range_, y0 + range_, p.y)]


## list: [[name, yTop], ...] from top to bottom; each bone owns the part below its y until the next one.
static func chain_y(list: Array, range_: float) -> Callable:
	return func(p: Vector3) -> Array:
		for i in list.size() - 1:
			var yb: float = list[i + 1][1]
			if p.y > yb - range_:
				return [list[i][0], list[i + 1][0], 1.0 - PNoise.smooth(yb - range_, yb + range_, p.y)]
		var l: String = list[list.size() - 1][0]
		return [l, l, 0.0]
