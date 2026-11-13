## Demo: the six heroes idling, walking and attacking with hit-stop, flash, stagger and camera shake.
## Keys: 1-4 change detail (0.4 / 0.5 / 0.75 / 1.0), Space = everyone attacks, C = toggle close camera.
## Command line: -- --shot=res://shot.png [--detail=0.5] [--close] saves a screenshot and quits.
extends Node3D

var heroes: Array[ProcHero] = []
var cam: Camera3D
var shake := 0.0
var detail := 0.5
var close := false
var label: Label
var shot_path := ""
var frame := 0
var t := 0.0
var bright := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="): shot_path = a.substr(7)
		elif a.begins_with("--detail="): detail = float(a.substr(9))
		elif a == "--close": close = true
		elif a == "--bright": bright = true
	_env()
	_spawn()
	label = Label.new()
	label.position = Vector2(12, 8)
	add_child(label)
	_update_label()


func _env() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.016, 0.026)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.27, 0.38)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.5
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.065, 0.1)
	env.fog_density = 0.02
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 0.9
	if bright:
		env.ambient_light_energy = 1.5
		env.ambient_light_color = Color(0.6, 0.6, 0.6)
		env.fog_enabled = false
	we.environment = env
	add_child(we)
	# cold moonlight
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 0.95)
	moon.light_energy = 2.0 if bright else 0.8
	moon.rotation_degrees = Vector3(-55, -30, 0)
	moon.shadow_enabled = true
	add_child(moon)
	# the warm lantern light that sells the scene
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.62, 0.3)
	lamp.light_energy = 6.0
	lamp.omni_range = 12.0
	lamp.omni_attenuation = 1.2
	lamp.position = Vector3(-1.5, 2.6, 2.6)
	lamp.shadow_enabled = true
	add_child(lamp)
	# ground
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.09, 0.075, 0.06)
	gm.roughness = 0.95
	ground.material_override = gm
	add_child(ground)
	cam = Camera3D.new()
	cam.fov = 40
	add_child(cam)
	_place_cam()


func _place_cam() -> void:
	if close:
		cam.position = Vector3(0, 1.8, 6.4)
		cam.look_at(Vector3(0, 1.0, 0))
	else:
		cam.position = Vector3(0, 6.5, 10.5)
		cam.look_at(Vector3(0, 0.8, 0))


func _spawn() -> void:
	for h in heroes: h.queue_free()
	heroes.clear()
	var n := ProcHeroes.ORDER.size()
	for i in n:
		var h := ProcHero.new()
		h.hero_id = ProcHeroes.ORDER[i]
		h.detail = detail
		h.shells = detail >= 0.99
		var x := (i - (n - 1) / 2.0) * (1.25 if close else 1.5)
		h.position = Vector3(x, 0, 0)
		add_child(h)
		h.set_meta("home", h.position)
		h.set_meta("next", 1.0 + i * 0.7)
		h.action_hit.connect(_on_hit.bind(h))
		heroes.append(h)


func _update_label() -> void:
	var tris := 0
	for h in heroes: tris += int(h.info.tris)
	label.text = "detail %.2f   %d heroes   %d triangles total   (1-4 detail, Space attack, C camera)" % [detail, heroes.size(), tris]


## the hit frame: freeze the attacker briefly, shake the camera, light flash at the weapon, the neighbour reacts
func _on_hit(action: String, h: ProcHero) -> void:
	h.time_scale = 0.0
	get_tree().create_timer(0.06).timeout.connect(func() -> void: h.time_scale = 1.0)
	shake = maxf(shake, 0.35)
	var flash := OmniLight3D.new()
	flash.light_color = Color(1, 0.8, 0.5)
	flash.light_energy = 6.0
	flash.omni_range = 2.5
	add_child(flash)
	flash.global_position = h.fx_point("tip")
	var tw := create_tween()
	tw.tween_property(flash, "light_energy", 0.0, 0.18)
	tw.tween_callback(flash.queue_free)
	var i := heroes.find(h)
	var other := heroes[(i + 1) % heroes.size()]
	other.hit_react(h.global_position - other.global_position, action != "attack")


func _process(dt: float) -> void:
	t += dt
	for h in heroes:
		var nxt: float = h.get_meta("next")
		var home: Vector3 = h.get_meta("home")
		if t > nxt and not h.is_acting():
			var r := randf()
			if r < 0.45:
				var acts := ["attack"]
				for a in ["bash", "cleave", "sunder", "volley", "kindle", "tonic", "hoar"]:
					if h.has_action(a): acts.append(a)
				h.combat = true
				h.play_action(acts.pick_random(), 0.32, 0.45)
				h.speed = 0.0
			elif r < 0.8:
				h.combat = false
				h.speed = [1.2, 1.6, 3.0].pick_random()
			else:
				h.speed = 0.0
				h.combat = randf() < 0.5
			h.set_meta("next", t + randf_range(1.5, 3.0))
		# walk on a small loop around home
		if h.speed > 0.0:
			var a: float = h.get_meta("ang", 0.0) + h.speed * dt / 0.8
			h.set_meta("ang", a)
			h.position = home + Vector3(sin(a) * 0.8, 0, (cos(a) - 1.0) * 0.8)
			h.rotation.y = a + PI / 2
		else:
			h.rotation.y = lerp_angle(h.rotation.y, 0.0, 1.0 - exp(-dt * 6.0))
	shake = maxf(0.0, shake - dt * 2.6)
	_place_cam()
	var s := shake * shake * 0.25
	cam.position += Vector3(randf_range(-s, s), randf_range(-s, s), 0)
	frame += 1
	if shot_path != "" and frame == 90:
		var img := get_viewport().get_texture().get_image()
		img.save_png(shot_path)
		print("saved ", shot_path)
		get_tree().quit()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed:
		match e.keycode:
			KEY_1: detail = 0.4; _spawn(); _update_label()
			KEY_2: detail = 0.5; _spawn(); _update_label()
			KEY_3: detail = 0.75; _spawn(); _update_label()
			KEY_4: detail = 1.0; _spawn(); _update_label()
			KEY_C: close = not close; _spawn(); _update_label()
			KEY_SPACE:
				for h in heroes:
					h.combat = true; h.speed = 0.0; h.play_action("attack", 0.3, 0.45)
