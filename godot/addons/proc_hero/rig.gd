## Bone list for a procedural figure. Bind pose: every rotation is identity and the bone heads sit at
## their model-space positions, so the Skeleton3D rest of each bone is just (head - parent head).
class_name ProcRig
extends RefCounted

var names := {}                      # name -> index
var bone_names: PackedStringArray
var parent := PackedInt32Array()
var head := PackedVector3Array()
var absolute := PackedByteArray()    # bones whose world rotation is set directly (hanging lanterns)


## defs: [[name, parent_name_or_null, x, y, z, absolute?], ...]
func _init(defs: Array) -> void:
	for i in defs.size():
		var d: Array = defs[i]
		names[d[0]] = i
		bone_names.append(d[0])
		parent.append(-1 if d[1] == null else int(names[d[1]]))
		head.append(Vector3(d[2], d[3], d[4]))
		absolute.append(1 if d.size() > 5 and d[5] else 0)


func size() -> int:
	return bone_names.size()


func index(n: String) -> int:
	assert(names.has(n), "unknown bone " + n)
	return names[n]


func make_skeleton() -> Skeleton3D:
	var sk := Skeleton3D.new()
	sk.name = "Skeleton3D"
	for i in size():
		sk.add_bone(bone_names[i])
	for i in size():
		var p := parent[i]
		sk.set_bone_parent(i, p)
		var off := head[i] - (head[p] if p >= 0 else Vector3.ZERO)
		sk.set_bone_rest(i, Transform3D(Basis.IDENTITY, off))
	sk.reset_bone_poses()
	return sk


## The shared humanoid rig. o: sh (shoulder half width), hp (hip half width), lan, lanB (lantern hooks)
static func human(o := {}) -> ProcRig:
	var sh: float = o.get("sh", 0.2)
	var hp: float = o.get("hp", 0.095)
	var lan: Vector3 = o.get("lan", Vector3(sh + 0.03, 0.835, 0))
	var lanB: Vector3 = o.get("lanB", Vector3(-0.14, 2.43, 0.07))
	return ProcRig.new([
		["root", null, 0, 0, 0], ["hips", "root", 0, 0.98, 0], ["spine", "hips", 0, 1.12, 0], ["chest", "spine", 0, 1.28, 0], ["neck", "chest", 0, 1.5, 0], ["head", "neck", 0, 1.585, 0.01],
		["lUp", "chest", sh, 1.435, 0], ["lFore", "lUp", sh + 0.02, 1.14, 0], ["lHand", "lFore", sh + 0.03, 0.885, 0],
		["rUp", "chest", -sh, 1.435, 0], ["rFore", "rUp", -sh - 0.02, 1.14, 0], ["rHand", "rFore", -sh - 0.03, 0.885, 0],
		["lThigh", "hips", hp, 0.93, 0], ["lShin", "lThigh", hp + 0.005, 0.5, 0], ["lFoot", "lShin", hp + 0.005, 0.085, 0],
		["rThigh", "hips", -hp, 0.93, 0], ["rShin", "rThigh", -hp - 0.005, 0.5, 0], ["rFoot", "rShin", -hp - 0.005, 0.085, 0],
		["cloakA", "chest", 0, 1.46, -0.1], ["cloakB", "cloakA", 0, 1.1, -0.15], ["cloakC", "cloakB", 0, 0.74, -0.17],
		["wR", "rHand", -sh - 0.03, 0.835, 0], ["wL", "lHand", sh + 0.03, 0.835, 0],
		["str", "wL", sh + 0.03, 0.835, 0], ["arw", "str", sh + 0.03, 0.835, 0], ["lan", "wL", lan.x, lan.y, lan.z, true],
		["back", "chest", 0, 1.3, -0.12], ["lanB", "back", lanB.x, lanB.y, lanB.z, true],
	])
