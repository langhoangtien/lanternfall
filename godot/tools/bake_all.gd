## godot --headless -s res://tools/bake_all.gd [-- --detail=0.5]
## Saves every hero mesh to res://baked/<id>_<detail>.res so the game loads them instead of building at startup.
extends SceneTree

func _init() -> void:
	var detail := 0.5
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--detail="): detail = float(a.substr(9))
	DirAccess.make_dir_recursive_absolute("res://baked")
	for id in ProcHeroes.ORDER:
		var m: Dictionary = ProcHero.get_mesh(id, detail, false)
		var path := "res://baked/%s_%d.res" % [id, int(detail * 100)]
		print(path, "  tris ", m.tris, "  err ", ResourceSaver.save(m.mesh, path))
	quit()
