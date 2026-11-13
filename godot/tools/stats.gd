## godot --headless -s res://tools/stats.gd   -> triangle counts and build times per hero / detail level
extends SceneTree

func _init() -> void:
	for cfg in [[1.0, true], [0.75, false], [0.5, false], [0.4, false]]:
		var line := "detail %.2f shells %-5s :" % [cfg[0], cfg[1]]
		for id in ProcHeroes.ORDER:
			var t0 := Time.get_ticks_msec()
			var b := ProcHeroes.build(id, cfg[0], cfg[1])
			var g: ProcGeo = b.geo
			var m := g.to_mesh()
			line += "  %s %d (%dms)" % [id, g.tri_count(), Time.get_ticks_msec() - t0]
		print(line)
	quit()
