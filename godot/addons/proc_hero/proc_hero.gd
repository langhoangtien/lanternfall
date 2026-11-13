## A procedural hero: builds the skinned mesh + Skeleton3D from a recipe and animates it procedurally.
##
##   var h := ProcHero.new()
##   h.hero_id = "warden"
##   add_child(h)
##   h.speed = 1.6            # m/s, drives the walk / run cycle (move the node yourself)
##   h.combat = true          # blend into the ready stance
##   h.play_action("attack")  # windup -> hit frame -> recovery
##   h.action_hit.connect(func(a): deal_damage())   # damage on the hit frame, not when the swing starts
##   h.hit_react(from_dir)    # flash + stagger when it gets hit
##
## The figure faces +Z.
@tool
class_name ProcHero
extends Node3D

signal action_hit(action: String)
signal action_done(action: String)

const SHADER := preload("res://addons/proc_hero/surf.gdshader")

@export_enum("warden", "reaver", "fletcher", "lamplighter", "apothecary", "rimebinder") var hero_id := "warden":
	set(v):
		hero_id = v
		if is_inside_tree(): rebuild()
## 1.0 = desktop. 0.5 is a good phone setting (about a third of the triangles).
@export_range(0.3, 1.0, 0.05) var detail := 0.5:
	set(v):
		detail = v
		if is_inside_tree(): rebuild()
## Thick cloth (back faces and rims). Off saves many triangles; the shader is double sided anyway.
@export var shells := false:
	set(v):
		shells = v
		if is_inside_tree(): rebuild()
## Use a mesh saved with "Bake mesh" instead of building at runtime (faster load on phones).
@export var baked_mesh: ArrayMesh
@export_tool_button("Bake mesh to res://baked/") var bake_btn := bake

## forward speed in m/s for the gait
@export var speed := 0.0
@export var combat := false
## multiply animation time (0 freezes: use it for hit-stop)
var time_scale := 1.0

var skeleton: Skeleton3D
var mesh_instance: MeshInstance3D
var anim: ProcHeroAnim
var info: Dictionary
var material: ShaderMaterial
var _flash := 0.0

static var _cache := {}


func _ready() -> void:
	rebuild()


func _key() -> String:
	return "%s|%.2f|%s" % [hero_id, detail, shells]


## Builds (or fetches from the cache) the mesh for this recipe.
static func get_mesh(id: String, p_detail: float, p_shells: bool) -> Dictionary:
	var key := "%s|%.2f|%s" % [id, p_detail, p_shells]
	if not _cache.has(key):
		var b := ProcHeroes.build(id, p_detail, p_shells)
		var g: ProcGeo = b.geo
		_cache[key] = {"mesh": g.to_mesh(), "rig": b.rig, "hide": b.hide, "fx": b.fx, "tris": g.tri_count(), "verts": g.P.size()}
	return _cache[key]


func rebuild() -> void:
	for c in get_children():
		if c == skeleton or c == mesh_instance:
			remove_child(c); c.queue_free()
	info = get_mesh(hero_id, detail, shells)
	var rig: ProcRig = info.rig
	skeleton = rig.make_skeleton()
	add_child(skeleton)
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Body"
	mesh_instance.mesh = baked_mesh if baked_mesh else info.mesh
	material = ShaderMaterial.new()
	material.shader = SHADER
	mesh_instance.material_override = material
	skeleton.add_child(mesh_instance)
	mesh_instance.skeleton = NodePath("..")
	anim = ProcHeroAnim.new(skeleton, rig, ProcHeroes.style(hero_id))
	for b in info.hide:
		anim.hide_bones[rig.index(b)] = 1
	anim.action_hit.connect(func(a: String) -> void: action_hit.emit(a))
	anim.action_done.connect(func(a: String) -> void: action_done.emit(a))
	anim.update(0.0, 0.0, false)


func _process(dt: float) -> void:
	if anim == null: return
	anim.update(dt * time_scale, speed, combat)
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - dt * 9.0)
		var k := _flash * _flash * 0.16
		material.set_shader_parameter("flash_color", Color(k * 1.2, k * 0.9, k * 0.6))


# ---------------------------------------------------------------- gameplay API
func play_action(action := "attack", windup := 0.3, recover := 0.4) -> bool:
	return anim.play(action, windup, recover)


func has_action(action: String) -> bool:
	return anim.st.clips.has(action)


func is_acting() -> bool:
	return anim.is_acting()


## Got hit. from_dir: world direction the blow came from (for the twist), heavy: bigger recoil.
func hit_react(from_dir := Vector3.ZERO, heavy := false) -> void:
	_flash = 1.0
	var side := 1.0
	if from_dir != Vector3.ZERO:
		side = signf(global_basis.x.dot(from_dir)) if absf(global_basis.x.dot(from_dir)) > 0.01 else 1.0
	anim.stagger(1.0 if heavy else 0.45, side)


func set_down(v: bool) -> void:
	anim.down = v


## World position of an effect point (sword tip, lantern...) for spawning particles. names: see ProcHeroes fx.
func fx_point(name: String) -> Vector3:
	if not info.fx.has(name): return global_position
	var f: Array = info.fx[name]
	var bi := skeleton.find_bone(f[0])
	var pose := skeleton.get_bone_global_pose(bi)
	var rest := (info.rig as ProcRig).head[bi]
	return skeleton.global_transform * (pose * ((f[1] as Vector3) - rest))


func dissolve(amount: float) -> void:
	material.set_shader_parameter("dissolve", amount)


func bake() -> void:
	var m := get_mesh(hero_id, detail, shells).mesh as ArrayMesh
	DirAccess.make_dir_recursive_absolute("res://baked")
	var path := "res://baked/%s_%d%s.res" % [hero_id, int(detail * 100), "_shells" if shells else ""]
	var err := ResourceSaver.save(m, path)
	print("baked ", path, " -> ", err)
	if err == OK:
		baked_mesh = load(path)
