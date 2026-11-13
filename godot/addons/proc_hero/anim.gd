## Procedural humanoid animator (port of HumanAnim in src/25-anim.js, without the leg IK pass).
## Every frame it composes, per bone, an Euler rotation and a translation offset from:
##   carry pose -> ready (combat) pose -> idle breathing -> walk/run cycle with planted feet ->
##   action clip (windup / hit / recover) -> stagger -> downed pose -> cloak and lantern springs
## and writes the result into a Skeleton3D.
class_name ProcHeroAnim
extends RefCounted

signal action_hit(action: String)    ## the hit frame of an action was reached: apply damage here
signal action_done(action: String)

const LEGB := ["hips", "lThigh", "lShin", "lFoot", "rThigh", "rShin", "rFoot"]

var sk: Skeleton3D
var rig: ProcRig
var st: Dictionary
var nb: int
var E: PackedVector3Array          # euler per bone (applied as Rx * Rz * Ry, like the original)
var Tr: PackedVector3Array         # translation offset per bone (parent space)
var ix := {}
var hide_bones := PackedByteArray()

var ph := randf() * TAU
var t := randf() * 20.0
var move_w := 0.0
var ready_w := 0.0
var foot_w := 0.0
var s_sm := -1.0
var last_speed := 0.0
var lgL := {"xf": 0.0, "xs": 0.0, "st": false}
var lgR := {"xf": 0.0, "xs": 0.0, "st": false}

var act: ProcClip
var act_name := ""
var act_t := 0.0
var act_w := 0.3
var act_r := 0.4
var act_u := 0.0
var hit_sent := false

var stag := 0.0
var stag_dir := 1.0
var down := false
var down_w := 0.0
var lead := 0.0
var aim_pitch := 0.0
var ck := PackedFloat32Array([0, 0, 0, 0, 0, 0])
var lan := PackedFloat32Array([0, 0, 0, 0])
var hy1 := NAN
var hy2 := NAN


func _init(p_sk: Skeleton3D, p_rig: ProcRig, style: Dictionary) -> void:
	sk = p_sk
	rig = p_rig
	st = style
	nb = rig.size()
	E.resize(nb); Tr.resize(nb)
	hide_bones.resize(nb)
	for i in nb: ix[rig.bone_names[i]] = i


## Start an action. windup = seconds until the hit frame, recover = seconds after it.
func play(name: String, windup := 0.3, recover := 0.4) -> bool:
	var c: ProcClip = st.clips.get(name)
	if c == null: return false
	act = c; act_name = name; act_t = 0.0; act_w = windup; act_r = recover; hit_sent = false
	return true


func is_acting() -> bool:
	return act != null


## Additive recoil. dir: +1 / -1 picks the twist direction.
func stagger(amount := 1.0, dir := 1.0) -> void:
	stag = maxf(stag, amount); stag_dir = dir


func _add(b: String, v: Vector3) -> void:
	E[ix[b]] += v


func _mix_pose(pose: Dictionary, w: float) -> void:
	for b in pose:
		if not ix.has(b): continue
		var i: int = ix[b]
		var v: Array = pose[b]
		E[i] = E[i].lerp(Vector3(v[0], v[1], v[2]), w)


static func _sm(a: float, b: float, x: float) -> float: return PNoise.smooth(a, b, x)
static func _k(dt: float, rate: float) -> float: return 1.0 - exp(-dt * rate)


## speed: forward ground speed in m/s (negative walks backwards). combat: blend into the ready pose.
func update(dt: float, speed: float, combat: bool) -> void:
	for i in nb:
		E[i] = Vector3.ZERO; Tr[i] = Vector3.ZERO
	t += dt
	var mv := minf(1.3, absf(speed) / 1.5)
	move_w = lerpf(move_w, 1.0 if mv > 0.05 else 0.0, _k(dt, 6.0 if mv > 0.05 else 5.0))
	ready_w = lerpf(ready_w, 1.0 if combat else 0.0, _k(dt, 6.0))
	if s_sm < 0.0: s_sm = absf(speed)
	s_sm = lerpf(s_sm, absf(speed), _k(dt, 5.0))
	var sa := s_sm
	foot_w = lerpf(foot_w, 1.0 if (combat and sa < 1.35) else 0.0, _k(dt, 6.0))
	var foot := foot_w
	# stride length grows with speed while cadence is capped: footwork 1.6 steps/s, walk 1.9, run 2.8
	var Ls := maxf(0.5, sa / 1.6) if sa < 1.35 else lerpf(maxf(0.78, sa / 1.95), sa / 2.75, _sm(2.3, 3.0, sa))
	Ls *= st.get("stride", 1.0)
	ph += speed * dt / Ls * PI
	var mw := move_w
	var rw := ready_w * (1.0 - mw * lerpf(0.45, 0.06, foot))
	var gt: Dictionary = st.get("gait", {})
	var I := ix

	# base carry + ready
	_mix_pose(st.carry, 1.0)
	if rw > 0.001: _mix_pose(st.ready, rw)
	if rw > 0.0: Tr[I.hips].y += st.get("readyRoot", 0.0) * rw
	# the standing pose gives way to the stride
	if mw > 0.01:
		var kk := 1.0 - mw * lerpf(0.85, 0.25, foot)
		for b in LEGB: E[I[b]] *= kk
	# idle life
	var br := sin(t * 1.5)
	var sw := sin(t * 0.43 + 1.0)
	var idle := 1.0 - mw
	E[I.chest].x += 0.014 * br; E[I.lUp].z += 0.012 * br; E[I.rUp].z -= 0.012 * br
	E[I.hips].z += 0.028 * sw * idle * (1.0 - rw); Tr[I.hips].x += 0.014 * sw * idle; E[I.spine].z -= 0.02 * sw * idle * (1.0 - rw)
	E[I.lShin].x += maxf(0.0, sw) * 0.09 * idle * (1.0 - rw); E[I.lThigh].x -= maxf(0.0, sw) * 0.05 * idle * (1.0 - rw)
	E[I.rShin].x += maxf(0.0, -sw) * 0.09 * idle * (1.0 - rw); E[I.rThigh].x -= maxf(0.0, -sw) * 0.05 * idle * (1.0 - rw)
	E[I.head].y += (0.16 * sin(t * 0.31) + 0.07 * sin(t * 0.87 + 2.0)) * idle; E[I.head].x += 0.03 * sin(t * 0.5)

	# walk / run
	if mw > 0.002:
		var LEG := 0.845
		var s := sin(ph)
		var c := cos(ph)
		var w := mw
		var armK := _sm(1.0, 2.0, sa)
		var stepD := speed * dt
		var legf := func(Tn: String, S: String, F: String, sg: float, cg: float, lg: Dictionary) -> void:
			# stance: the foot moves back at ground speed so it stays where it was planted; swing: carried forward
			var q := (atan2(sg, cg) - PI / 2) / PI
			q = fmod(fmod(q, 2.0) + 2.0, 2.0)
			var xf: float
			if q < 1.0:
				if not lg.st:
					lg.st = true; lg.xf = clampf(lg.xf, Ls * 0.28, Ls * 0.44)
				lg.xf -= stepD; xf = lg.xf
			else:
				if lg.st:
					lg.st = false; lg.xs = lg.xf
				var u := q - 1.0
				lg.xf = lerpf(lg.xs, Ls * 0.38, u * u * (3.0 - 2.0 * u)); xf = lg.xf
			var th := asin(clampf(xf / LEG, -0.78, 0.78))
			var flex := 0.06 + lerpf(lerpf(0.62, 1.05, _sm(2.2, 3.2, sa)), 0.5, foot) * pow(maxf(0.0, cos(atan2(sg, cg) + 0.35)), 1.6) * (0.6 + 0.4 * mv)
			var swing := maxf(0.0, cg)
			E[I[Tn]].x += -th * w
			E[I[S]].x += flex * w
			E[I[F]].x += ((th - flex) * (1.0 - swing * 0.6) + 0.3 * pow(maxf(0.0, cos(atan2(sg, cg) + 1.3)), 2.0) - 0.22 * swing * maxf(0.0, sg)) * w
		legf.call("lThigh", "lShin", "lFoot", s, c, lgL)
		legf.call("rThigh", "rShin", "rFoot", -s, -c, lgR)
		# hips drop so the stride can reach, plus a small bob twice per stride
		var runK := _sm(2.4, 3.5, sa)
		var bobA := minf(lerpf(0.025, 0.04, runK), lerpf(0.018, 0.032, runK) * gt.get("bounce", 1.0))
		var fr := minf(0.72 * LEG, Ls * 0.38)
		var need := LEG - sqrt(LEG * LEG - fr * fr)
		Tr[I.hips].y += (-need - 0.012 + bobA * (1.0 + cos(ph * 2.0))) * w
		E[I.hips].y += -0.05 * s * w; E[I.hips].z += 0.03 * c * w; E[I.spine].y += 0.13 * s * w; E[I.chest].y += 0.1 * s * w; E[I.spine].x += (0.02 + 0.03 * mv) * w; E[I.head].y += -0.05 * s * w
		var sl: float = st.get("swingL", 1.0) * armK
		var sr: float = st.get("swingR", 1.0) * armK
		var B := 0.42 * (0.6 + 0.4 * mv)
		E[I.lUp].x += B * s * w * sl; E[I.rUp].x += -B * s * w * sr
		E[I.lFore].x += -(0.18 + 0.22 * maxf(0.0, -s)) * w * sl; E[I.rFore].x += -(0.18 + 0.22 * maxf(0.0, s)) * w * sr
		# looser body: bounce, sway, counter-rotation, lean into the run, a steady head
		var run := _sm(2.4, 3.5, absf(speed))
		var bo: float = gt.get("bounce", 1.0)
		var sy: float = gt.get("sway", 1.0)
		var ln: float = gt.get("lean", 1.0)
		var dx := -0.014 * sy * c * w
		Tr[I.hips].x += dx; E[I.lThigh].z -= dx / LEG; E[I.rThigh].z -= dx / LEG
		E[I.hips].y += -0.04 * s * w * (1.0 + run * 2.5); E[I.hips].z += 0.02 * sy * c * w; E[I.spine].z += -0.035 * sy * c * w; E[I.chest].y += 0.17 * s * w * (1.0 + run * 0.6); E[I.chest].z += -0.03 * sy * c * w
		E[I.spine].x += (0.015 * ln + 0.17 * run) * w; E[I.chest].x += 0.03 * cos(ph * 2.0) * w * bo; E[I.neck].x -= (0.05 * ln + 0.12 * run) * w
		E[I.head].y -= 0.2 * s * w * (1.0 + run * 0.5); E[I.head].z += 0.035 * sy * c * w; E[I.head].x -= 0.025 * cos(ph * 2.0) * w * bo
		var kl := pow(maxf(0.0, cos(ph + 0.35)), 1.6)
		var kr := pow(maxf(0.0, -cos(ph + 0.35)), 1.6)
		var lift: float = gt.get("lift", 1.0)
		E[I.lShin].x += (0.2 * (lift - 1.0) + run * 0.55) * kl * w; E[I.rShin].x += (0.2 * (lift - 1.0) + run * 0.55) * kr * w
		E[I.lThigh].x -= run * 0.22 * maxf(0.0, c) * w; E[I.rThigh].x -= run * 0.22 * maxf(0.0, -c) * w
		E[I.lFore].x -= 0.55 * run * w * sl; E[I.rFore].x -= 0.55 * run * w * sr; E[I.lUp].x += 0.25 * B * s * run * w * sl; E[I.rUp].x -= 0.25 * B * s * run * w * sr
		E[I.lUp].z += 0.05 * w; E[I.rUp].z -= 0.05 * w

	# action clip: 0..hit over the windup, hit..1 over the recovery
	var root_z := 0.0
	if act:
		act_t += dt
		var u := act_t / act_w * act.hit if act_t < act_w else act.hit + (act_t - act_w) / act_r * (1.0 - act.hit)
		act_u = u
		if not hit_sent and u >= act.hit:
			hit_sent = true
			action_hit.emit(act_name)
		if u >= 1.0:
			var done := act_name
			act = null; act_name = ""
			action_done.emit(done)
		else:
			var w := minf(1.0, u / 0.07) * minf(1.0, (1.0 - u) / 0.16)
			for n in act.tracks:
				E[I[n]] = E[I[n]].lerp(ProcClip.sample(act.tracks[n], u), w)
			for n in act.ttracks:
				Tr[I[n]] += ProcClip.sample(act.ttracks[n], u) * w
			var rv := ProcClip.sample(act.root, u)
			Tr[I.root].x += rv.x * w; Tr[I.hips].y += rv.y * w; Tr[I.root].z += rv.z * w; root_z = rv.z * w
	# the body turns first
	if lead != 0.0:
		E[I.chest].y += lead * 0.45; E[I.spine].y += lead * 0.2; E[I.head].y += lead * 0.5; E[I.hips].y -= lead * 0.25; E[I.spine].z -= lead * 0.08 * mw
	# stagger (additive recoil)
	if stag > 0.0:
		stag = maxf(0.0, stag - dt * 2.6)
		var k := sin(minf(1.0, stag) * PI) * 0.9 + stag * 0.3
		E[I.spine].x -= 0.22 * k; E[I.chest].x -= 0.2 * k; E[I.head].x += 0.25 * k; E[I.hips].y += 0.2 * k * stag_dir; Tr[I.root].z -= 0.12 * k
		E[I.lUp].z += 0.2 * k; E[I.rUp].z -= 0.2 * k
		E[I.lShin].x += 0.2 * k; E[I.rShin].x += 0.2 * k; E[I.lThigh].x -= 0.1 * k; E[I.rThigh].x -= 0.1 * k; Tr[I.hips].y -= 0.03 * k
	# downed: one knee, head bowed
	down_w = lerpf(down_w, 1.0 if down else 0.0, _k(dt, 3.2 if down else 4.0))
	if down_w > 0.002:
		_mix_pose(ProcHeroes.DOWN_POSE, down_w)
		Tr[I.hips].y = lerpf(Tr[I.hips].y, -0.46, down_w); Tr[I.hips].z = lerpf(Tr[I.hips].z, -0.05, down_w)
	if aim_pitch != 0.0:
		E[I.spine].x -= aim_pitch * 0.4; E[I.chest].x -= aim_pitch * 0.4
	# cloak: lags behind motion, counter-rotates the torso lean (three chained damped springs)
	var lean := E[I.spine].x + E[I.chest].x + E[I.hips].x
	var wind := 0.05 * sin(t * 1.3) + 0.03 * sin(t * 3.1 + 1.0)
	var tgtA := -lean * 0.85 + 0.07 + maxf(0.0, speed) * 0.2 + wind + 0.025 * cos(ph * 2.0) * mw
	ck[1] += ((tgtA - ck[0]) * 60.0 - ck[1] * 13.0) * dt; ck[0] += ck[1] * dt
	ck[3] += (((ck[0] - tgtA) * -0.6 + maxf(0.0, speed) * 0.1 + wind * 1.4 + 0.04 - ck[2]) * 40.0 - ck[3] * 6.0) * dt; ck[2] += ck[3] * dt
	ck[5] += ((ck[2] * 0.6 + wind - ck[4]) * 30.0 - ck[5] * 5.0) * dt; ck[4] += ck[5] * dt
	E[I.cloakA].x = clampf(ck[0], -0.08, 0.5); E[I.cloakB].x = clampf(ck[2], -0.1, 0.32); E[I.cloakC].x = clampf(ck[4], -0.12, 0.3)
	E[I.cloakA].z = -E[I.hips].z - E[I.spine].z + 0.03 * sin(t * 0.9) + 0.05 * sin(ph - 0.5) * mw
	E[I.cloakA].y = -(E[I.chest].y + E[I.spine].y) * 0.6
	E[I.cloakB].z = 0.1 * sin(ph - 1.1) * mw - lead * 0.2; E[I.cloakC].z = 0.14 * sin(ph - 1.8) * mw - lead * 0.25
	# lantern pendulum
	var acc := (speed - last_speed) / maxf(dt, 1e-3)
	last_speed = speed
	var drive := -clampf(acc, -30, 30) * 0.012 + sin(ph * 2.0) * 0.05 * mw + root_z * -0.6
	lan[1] += ((drive - lan[0]) * 38.0 - lan[1] * 2.2) * dt; lan[0] += lan[1] * dt
	lan[3] += ((sin(ph) * 0.05 * mw + 0.02 * sin(t * 1.7) - lan[2]) * 30.0 - lan[3] * 2.0) * dt; lan[2] += lan[3] * dt
	# the arrow is only visible while it is nocked
	if st.has("arrow_bone"):
		hide_bones[I[st.arrow_bone]] = 0 if (act and act_u > 0.12 and act_u < act.hit) else 1
	# smooth the hip height (removes pops when clips start or stop)
	var hy := Tr[I.hips].y
	var kh := _k(dt, 28.0)
	if is_nan(hy1) or dt <= 0.0:
		hy1 = hy; hy2 = hy
	hy1 += (hy - hy1) * kh; hy2 += (hy1 - hy2) * kh
	Tr[I.hips].y = hy2
	_apply()


static func euler_basis(e: Vector3) -> Basis:
	return Basis(Vector3.RIGHT, e.x) * Basis(Vector3.BACK, e.z) * Basis(Vector3.UP, e.y)


## write the pose into the skeleton (local rotation + rest offset + translation)
func _apply() -> void:
	var glob: Array[Basis] = []
	glob.resize(nb)
	var abs_b := euler_basis(Vector3(clampf(lan[0], -0.9, 0.9), 0, clampf(lan[2], -0.6, 0.6)))
	for i in nb:
		var p := rig.parent[i]
		var b: Basis
		if rig.absolute[i]:
			b = glob[p].inverse() * abs_b
			glob[i] = abs_b
		else:
			b = euler_basis(E[i])
			glob[i] = (glob[p] * b) if p >= 0 else b
		sk.set_bone_pose_rotation(i, b.get_rotation_quaternion())
		var off := rig.head[i] - (rig.head[p] if p >= 0 else Vector3.ZERO)
		sk.set_bone_pose_position(i, off + Tr[i])
		sk.set_bone_pose_scale(i, Vector3.ONE * 0.0001 if hide_bones[i] else Vector3.ONE)
