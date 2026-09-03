extends CharacterBody3D

signal health_changed(health_value)

@onready var camera: Camera3D = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $Camera3D/Pistol/MuzzleFlash
@onready var weapon_model_root = $Camera3D/Pistol/Model
@onready var body_mesh = $MeshInstance3D
@onready var weapon_audio = $WeaponAudio
@onready var player_ui = $PlayerUI
@onready var weapon_menu = $PlayerUI/WeaponMenu
@onready var weapon_label = $PlayerUI/WeaponLabel
@onready var scope_overlay = $PlayerUI/ScopeOverlay
@onready var primary_option = $PlayerUI/WeaponMenu/Margin/VBox/PrimaryRow/Option
@onready var secondary_option = $PlayerUI/WeaponMenu/Margin/VBox/SecondaryRow/Option
@onready var knife_option = $PlayerUI/WeaponMenu/Margin/VBox/KnifeRow/Option
@onready var name_tag: Label3D = $NameTag

const MAX_HEALTH := 100
var health := MAX_HEALTH

var spawn_position := Vector3.ZERO

# Replicated look / identity state (see SceneReplicationConfig in player.tscn).
var player_color := Color(1, 1, 1) : set = _set_player_color
var player_name := "Player" : set = _set_player_name
var surf_mode := false : set = _set_surf_mode
var current_weapon_id := "pistol" : set = _set_current_weapon_id

# --- Weapons ------------------------------------------------------------------
# damage 1000 = instant kill. mag 0 = melee (no ammo / reload).
const MELEE_RANGE := 2.5
var WEAPONS := {
	"knife":     {"name": "Knife",           "slot": "knife",     "damage": 40,   "cooldown": 0.45, "auto": false, "melee": true,  "mag": 0,  "reload": 0.0, "pellets": 1, "sfx": "knife_swing"},
	"balisong":  {"name": "Balisong",        "slot": "knife",     "damage": 45,   "cooldown": 0.35, "auto": false, "melee": true,  "mag": 0,  "reload": 0.0, "pellets": 1, "sfx": "knife_swing"},
	"karambit":  {"name": "Karambit",        "slot": "knife",     "damage": 55,   "cooldown": 0.50, "auto": false, "melee": true,  "mag": 0,  "reload": 0.0, "pellets": 1, "sfx": "knife_swing"},

	"pistol":          {"name": "Pistol",          "slot": "secondary", "damage": 20, "cooldown": 0.22, "auto": false, "melee": false, "mag": 12, "reload": 1.6, "pellets": 1, "sfx": "fire_pistol"},
	"pistol_silenced": {"name": "Silenced Pistol", "slot": "secondary", "damage": 18, "cooldown": 0.22, "auto": false, "melee": false, "mag": 12, "reload": 1.7, "pellets": 1, "sfx": "fire_silenced"},
	"revolver":        {"name": "Revolver",        "slot": "secondary", "damage": 45, "cooldown": 0.55, "auto": false, "melee": false, "mag": 6,  "reload": 2.2, "pellets": 1, "sfx": "fire_revolver"},

	"ak47":    {"name": "AK-47",   "slot": "primary", "damage": 26,   "cooldown": 0.14, "auto": false, "melee": false, "mag": 25, "reload": 2.4, "pellets": 1, "sfx": "fire_ak"},
	"sniper":  {"name": "Sniper",  "slot": "primary", "damage": 1000, "cooldown": 1.40, "auto": false, "melee": false, "mag": 5,  "reload": 2.8, "pellets": 1, "sfx": "fire_sniper"},
	"shotgun": {"name": "Shotgun", "slot": "primary", "damage": 66,   "cooldown": 0.85, "auto": false, "melee": false, "mag": 5,  "reload": 3.0, "pellets": 8, "sfx": "fire_shotgun"},
	"smg":     {"name": "SMG",     "slot": "primary", "damage": 14,   "cooldown": 0.07, "auto": true,  "melee": false, "mag": 30, "reload": 2.1, "pellets": 1, "sfx": "fire_smg"},
}

# Procedural weapon models: each is a list of primitive parts.
#   t = "box"/"cyl"/"torus", s = size (box: full extents; cyl: x=radius y=height; torus: x=inner y=outer),
#   p = local position, r = euler degrees (optional), c = colour
const _METAL := Color(0.16, 0.16, 0.18)
const _DARK  := Color(0.09, 0.09, 0.10)
const _WOOD  := Color(0.42, 0.26, 0.12)
const _STEEL := Color(0.62, 0.62, 0.67)
const _GREEN := Color(0.20, 0.34, 0.20)
const _PLAS  := Color(0.13, 0.13, 0.15)
var MODELS := {
	"pistol": [
		{"t": "box", "s": Vector3(0.05, 0.06, 0.18), "p": Vector3(0, 0, -0.02), "c": _METAL},
		{"t": "box", "s": Vector3(0.03, 0.03, 0.07), "p": Vector3(0, 0.012, -0.13), "c": _DARK},
		{"t": "box", "s": Vector3(0.045, 0.11, 0.05), "p": Vector3(0, -0.08, 0.04), "r": Vector3(18, 0, 0), "c": _DARK},
	],
	"pistol_silenced": [
		{"t": "box", "s": Vector3(0.05, 0.06, 0.18), "p": Vector3(0, 0, -0.02), "c": _METAL},
		{"t": "box", "s": Vector3(0.045, 0.11, 0.05), "p": Vector3(0, -0.08, 0.04), "r": Vector3(18, 0, 0), "c": _DARK},
		{"t": "cyl", "s": Vector3(0.028, 0.16, 0), "p": Vector3(0, 0.012, -0.2), "r": Vector3(90, 0, 0), "c": _DARK},
	],
	"revolver": [
		{"t": "box", "s": Vector3(0.045, 0.06, 0.12), "p": Vector3(0, 0, -0.02), "c": _STEEL},
		{"t": "cyl", "s": Vector3(0.042, 0.06, 0), "p": Vector3(0, 0, -0.01), "r": Vector3(90, 0, 0), "c": _METAL},
		{"t": "cyl", "s": Vector3(0.018, 0.13, 0), "p": Vector3(0, 0.012, -0.13), "r": Vector3(90, 0, 0), "c": _STEEL},
		{"t": "box", "s": Vector3(0.04, 0.1, 0.05), "p": Vector3(0, -0.07, 0.04), "r": Vector3(24, 0, 0), "c": _WOOD},
	],
	"ak47": [
		{"t": "box", "s": Vector3(0.05, 0.07, 0.34), "p": Vector3(0, 0, -0.05), "c": _METAL},
		{"t": "cyl", "s": Vector3(0.012, 0.24, 0), "p": Vector3(0, 0.016, -0.3), "r": Vector3(90, 0, 0), "c": _DARK},
		{"t": "box", "s": Vector3(0.038, 0.15, 0.06), "p": Vector3(0, -0.1, -0.02), "r": Vector3(-25, 0, 0), "c": _WOOD},
		{"t": "box", "s": Vector3(0.045, 0.05, 0.1), "p": Vector3(0, -0.04, -0.16), "c": _WOOD},
		{"t": "box", "s": Vector3(0.04, 0.06, 0.17), "p": Vector3(0, -0.005, 0.17), "c": _WOOD},
		{"t": "box", "s": Vector3(0.01, 0.03, 0.02), "p": Vector3(0, 0.045, -0.34), "c": _DARK},
	],
	"sniper": [
		{"t": "box", "s": Vector3(0.05, 0.07, 0.32), "p": Vector3(0, 0, -0.02), "c": _GREEN},
		{"t": "cyl", "s": Vector3(0.012, 0.44, 0), "p": Vector3(0, 0.01, -0.42), "r": Vector3(90, 0, 0), "c": _DARK},
		{"t": "cyl", "s": Vector3(0.03, 0.2, 0), "p": Vector3(0, 0.075, -0.05), "r": Vector3(90, 0, 0), "c": _DARK},
		{"t": "box", "s": Vector3(0.015, 0.045, 0.015), "p": Vector3(0, 0.045, 0.01), "c": _DARK},
		{"t": "box", "s": Vector3(0.015, 0.045, 0.015), "p": Vector3(0, 0.045, -0.11), "c": _DARK},
		{"t": "box", "s": Vector3(0.06, 0.014, 0.014), "p": Vector3(0.04, 0.02, 0.06), "c": _STEEL},
		{"t": "box", "s": Vector3(0.036, 0.06, 0.05), "p": Vector3(0, -0.06, -0.05), "c": _GREEN},
		{"t": "box", "s": Vector3(0.045, 0.09, 0.2), "p": Vector3(0, -0.02, 0.22), "c": _GREEN},
	],
	"shotgun": [
		{"t": "box", "s": Vector3(0.05, 0.07, 0.16), "p": Vector3(0, 0, 0), "c": _STEEL},
		{"t": "cyl", "s": Vector3(0.022, 0.42, 0), "p": Vector3(0, 0.02, -0.3), "r": Vector3(90, 0, 0), "c": _METAL},
		{"t": "cyl", "s": Vector3(0.016, 0.36, 0), "p": Vector3(0, -0.022, -0.28), "r": Vector3(90, 0, 0), "c": _METAL},
		{"t": "box", "s": Vector3(0.05, 0.05, 0.1), "p": Vector3(0, -0.038, -0.18), "c": _WOOD},
		{"t": "box", "s": Vector3(0.045, 0.09, 0.22), "p": Vector3(0, -0.02, 0.2), "c": _WOOD},
	],
	"smg": [
		{"t": "box", "s": Vector3(0.045, 0.08, 0.22), "p": Vector3(0, 0, -0.02), "c": _PLAS},
		{"t": "cyl", "s": Vector3(0.02, 0.12, 0), "p": Vector3(0, 0.01, -0.16), "r": Vector3(90, 0, 0), "c": _DARK},
		{"t": "box", "s": Vector3(0.03, 0.14, 0.045), "p": Vector3(0, -0.1, -0.02), "r": Vector3(-8, 0, 0), "c": _PLAS},
		{"t": "box", "s": Vector3(0.04, 0.06, 0.05), "p": Vector3(0, -0.04, -0.11), "c": _PLAS},
		{"t": "box", "s": Vector3(0.03, 0.05, 0.12), "p": Vector3(0, 0.01, 0.16), "c": _DARK},
		{"t": "box", "s": Vector3(0.04, 0.09, 0.045), "p": Vector3(0, -0.07, 0.05), "r": Vector3(15, 0, 0), "c": _PLAS},
	],
	"knife": [
		{"t": "box", "s": Vector3(0.016, 0.03, 0.17), "p": Vector3(0, 0.012, -0.1), "c": _STEEL},
		{"t": "box", "s": Vector3(0.026, 0.036, 0.09), "p": Vector3(0, 0, 0.02), "c": _DARK},
		{"t": "box", "s": Vector3(0.05, 0.016, 0.016), "p": Vector3(0, 0, -0.02), "c": _STEEL},
	],
	"balisong": [
		{"t": "box", "s": Vector3(0.013, 0.026, 0.15), "p": Vector3(0, 0.02, -0.09), "c": _STEEL},
		{"t": "box", "s": Vector3(0.014, 0.02, 0.1), "p": Vector3(0.022, -0.01, 0.02), "r": Vector3(0, 0, 12), "c": _METAL},
		{"t": "box", "s": Vector3(0.014, 0.02, 0.1), "p": Vector3(-0.022, -0.01, 0.02), "r": Vector3(0, 0, -12), "c": _METAL},
	],
	"karambit": [
		{"t": "box", "s": Vector3(0.013, 0.022, 0.12), "p": Vector3(0, 0.035, -0.06), "r": Vector3(38, 0, 0), "c": _STEEL},
		{"t": "box", "s": Vector3(0.022, 0.032, 0.08), "p": Vector3(0, -0.01, 0.03), "r": Vector3(-10, 0, 0), "c": _DARK},
		{"t": "torus", "s": Vector3(0.012, 0.024, 0), "p": Vector3(0, -0.025, 0.08), "r": Vector3(90, 0, 0), "c": _DARK},
	],
}

var loadout := {"primary": "ak47", "secondary": "pistol", "knife": "knife"}
var current_slot := "secondary"
var _ammo := {}
var _reloading := false
var _reload_done := 0.0
var _next_fire_time := 0.0
var _fire_queued := false
var _menu_open := false
var _scoped := false
var _base_fov := 75.0

# --- Movement tuning (GoldSrc / Source PM_ model) ---------------------------
const GROUND_SPEED  := 8.0
const STOP_SPEED    := 2.5
const FRICTION      := 4.0
const GROUND_ACCEL  := 10.0
const AIR_ACCEL     := 10.0
const MAX_AIR_SPEED := 0.8
const JUMP_HEIGHT   := 1.143
var gravity := 20.32

# Surf mode (world.gd turns this on for the Surf map).
const SURF_FLOOR_MAX_ANGLE_DEG := 25.0
const SURF_GRAVITY      := 16.0    # only used along the ramp, gated by look-down
const SURF_ACCEL        := 7.0     # semi-slow accel along the ramp toward where you look
const SURF_TARGET_SPEED := 20.0
const SURF_MAX_SPEED    := 42.0
const SURF_STICK        := 6.0     # keeps you pressed to the ramp face
const SURF_AIR_ACCEL    := 45.0    # airborne between ramps
const SURF_AIR_CAP      := 3.0

# DEBUG jump sound. TODO: remove (and jump_debug.wav).
var _jump_sfx: AudioStreamPlayer

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	add_to_group("players")
	_apply_color()
	_build_weapon_model()
	_set_surf_mode(surf_mode)
	_set_player_name(player_name)

	if not is_multiplayer_authority():
		if player_ui:
			player_ui.queue_free()
		return

	# You don't see your own floating name tag.
	if name_tag:
		name_tag.hide()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	_base_fov = camera.fov

	var w = get_parent()
	if w != null:
		var c = w.get("local_color")
		if c != null:
			player_color = c
		var nm = w.get("local_name")
		if nm != null and str(nm) != "":
			player_name = nm

	_jump_sfx = AudioStreamPlayer.new()
	_jump_sfx.stream = load("res://jump_debug.wav")
	add_child(_jump_sfx)

	weapon_menu.visible = false
	scope_overlay.visible = false
	_populate_option(primary_option, "primary")
	_populate_option(secondary_option, "secondary")
	_populate_option(knife_option, "knife")
	_update_weapon_label()

func _unhandled_input(event):
	if not is_multiplayer_authority():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _set_slot("primary")
			KEY_2: _set_slot("secondary")
			KEY_3: _set_slot("knife")
			KEY_R: _start_reload()
			KEY_B: _toggle_menu()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if current_weapon_id == "sniper" and not _menu_open:
			_set_scoped(not _scoped)

	if _menu_open:
		return

	if event is InputEventMouseMotion:
		var s := 0.005 * (0.35 if _scoped else 1.0)
		rotate_y(-event.relative.x * s)
		camera.rotate_x(-event.relative.y * s)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

	if event.is_action_pressed("shoot") and not _current_weapon()["auto"]:
		_fire_queued = true   # consumed in _physics_process so the raycast runs during physics

func _physics_process(delta):
	if not is_multiplayer_authority():
		return

	if _reloading and Time.get_ticks_msec() / 1000.0 >= _reload_done:
		_reloading = false
		_ammo[current_weapon_id] = int(_current_weapon()["mag"])
		_update_weapon_label()

	var grounded := is_on_floor()
	var on_ramp := surf_mode and not grounded and is_on_wall()
	var g: float = SURF_GRAVITY if surf_mode else gravity

	if not grounded and not on_ramp:
		velocity.y -= g * delta

	var jumped := false
	if not _menu_open and Input.is_action_just_pressed("ui_accept") and (grounded or on_ramp):
		velocity.y = sqrt(2.0 * (gravity if not surf_mode else 14.0) * JUMP_HEIGHT)
		if on_ramp:
			velocity += get_wall_normal() * 3.0
		jumped = true
		if _jump_sfx and _jump_sfx.stream:
			_jump_sfx.play()

	var input_dir := Vector2.ZERO
	if not _menu_open:
		input_dir = Input.get_vector("left", "right", "up", "down")
	var wishdir := transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	wishdir.y = 0.0
	wishdir = wishdir.normalized()

	if grounded and not jumped:
		_apply_friction(delta)
		_accelerate(wishdir, GROUND_SPEED, GROUND_ACCEL, delta)
	elif on_ramp and not jumped:
		_surf_ramp_movement(delta, get_wall_normal())
	elif surf_mode:
		_air_accelerate(wishdir, GROUND_SPEED, SURF_AIR_ACCEL, delta, SURF_AIR_CAP)
	else:
		_air_accelerate(wishdir, GROUND_SPEED, AIR_ACCEL, delta)

	if _fire_queued or (not _menu_open and _current_weapon()["auto"] and Input.is_action_pressed("shoot")):
		_try_fire()
	_fire_queued = false

	if anim_player.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and grounded:
		anim_player.play("move")
	else:
		anim_player.play("idle")

	move_and_slide()

# --- Movement primitives ---------------------------------------------------

func _apply_friction(delta: float) -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	if speed < 0.1:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var control := speed if speed >= STOP_SPEED else STOP_SPEED
	var drop := control * FRICTION * delta
	var newspeed := maxf(speed - drop, 0.0) / speed
	velocity.x *= newspeed
	velocity.z *= newspeed

func _accelerate(wishdir: Vector3, wishspeed: float, accel: float, delta: float) -> void:
	var currentspeed := Vector2(velocity.x, velocity.z).dot(Vector2(wishdir.x, wishdir.z))
	var addspeed := wishspeed - currentspeed
	if addspeed <= 0.0:
		return
	var accelspeed := minf(accel * wishspeed * delta, addspeed)
	velocity.x += accelspeed * wishdir.x
	velocity.z += accelspeed * wishdir.z

func _air_accelerate(wishdir: Vector3, wishspeed: float, accel: float, delta: float, air_cap: float = MAX_AIR_SPEED) -> void:
	var wishspd := minf(wishspeed, air_cap)
	var currentspeed := Vector2(velocity.x, velocity.z).dot(Vector2(wishdir.x, wishdir.z))
	var addspeed := wishspd - currentspeed
	if addspeed <= 0.0:
		return
	var accelspeed := minf(accel * wishspeed * delta, addspeed)
	velocity.x += accelspeed * wishdir.x
	velocity.z += accelspeed * wishdir.z

# Surf: you STICK to the ramp face. Gravity only pulls you down the slope in
# proportion to how far down you're looking. Acceleration toward the look
# direction (along the ramp) is deliberately gentle.
func _surf_ramp_movement(delta: float, n: Vector3) -> void:
	var look := -camera.global_transform.basis.z
	var along := look - n * look.dot(n)
	if along.length() > 0.001:
		along = along.normalized()
	var look_down := clampf(-look.y, 0.0, 1.0)

	var g_along := Vector3(0, -SURF_GRAVITY, 0)
	g_along -= n * g_along.dot(n)
	velocity += g_along * look_down * delta

	# Accel along the ramp only kicks in while you're looking down it - look level
	# and you just coast on the speed you have (no friction here).
	var along_speed := velocity.dot(along)
	var add := SURF_TARGET_SPEED - along_speed
	if add > 0.0:
		velocity += along * minf(SURF_ACCEL * delta, add) * look_down

	# Hug the ramp: cancel any drift away from it, then a little suction.
	var into := velocity.dot(n)
	if into > 0.0:
		velocity -= n * into
	velocity -= n * SURF_STICK * delta

	var flat := Vector2(velocity.x, velocity.z)
	if flat.length() > SURF_MAX_SPEED:
		flat = flat.normalized() * SURF_MAX_SPEED
		velocity.x = flat.x
		velocity.z = flat.y

# --- Weapons -------------------------------------------------------------------

func _current_weapon() -> Dictionary:
	return WEAPONS.get(current_weapon_id, WEAPONS["pistol"])

func _ammo_for(id: String) -> int:
	if not _ammo.has(id):
		_ammo[id] = int(WEAPONS[id].get("mag", 0))
	return _ammo[id]

func _set_slot(slot: String) -> void:
	if not loadout.has(slot):
		return
	current_slot = slot
	current_weapon_id = loadout[slot]

func _toggle_menu() -> void:
	_menu_open = not _menu_open
	if weapon_menu:
		weapon_menu.visible = _menu_open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _menu_open else Input.MOUSE_MODE_CAPTURED

func _set_scoped(v: bool) -> void:
	_scoped = v and current_weapon_id == "sniper"
	if camera:
		camera.fov = 22.0 if _scoped else _base_fov
	if is_instance_valid(scope_overlay):
		scope_overlay.visible = _scoped
	if weapon_model_root:
		weapon_model_root.visible = not _scoped

func _start_reload() -> void:
	var w := _current_weapon()
	if int(w.get("mag", 0)) <= 0 or _reloading:
		return
	if _ammo_for(current_weapon_id) >= int(w["mag"]):
		return
	_reloading = true
	_reload_done = Time.get_ticks_msec() / 1000.0 + float(w["reload"])
	_play_sound("reload")
	_update_weapon_label()

func _try_fire() -> void:
	if _menu_open or _reloading:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now < _next_fire_time:
		return
	var w := _current_weapon()
	var melee: bool = w["melee"]

	if not melee:
		if _ammo_for(current_weapon_id) <= 0:
			_start_reload()
			return
		_ammo[current_weapon_id] -= 1

	_next_fire_time = now + float(w["cooldown"])
	play_shoot_effects.rpc(String(w["sfx"]), bool(w["melee"]))

	var pellets := int(w["pellets"])
	for i in pellets:
		_fire_ray(w, pellets)

	_update_weapon_label()
	if not melee and _ammo_for(current_weapon_id) <= 0:
		_start_reload()

func _fire_ray(w: Dictionary, pellets: int) -> void:
	var from := camera.global_position
	var dir := -camera.global_transform.basis.z
	if pellets > 1:
		dir = (dir + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * 0.05).normalized()

	# Melee weapons only reach MELEE_RANGE - a genuinely short lunge, not a shot.
	var reach: float = MELEE_RANGE if w["melee"] else 120.0
	var params := PhysicsRayQueryParameters3D.create(from, from + dir * reach)
	params.collision_mask = 2
	params.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(params)
	if hit.is_empty():
		return
	var body = hit["collider"]
	if body == null or not body.has_method("receive_damage"):
		return
	if w["melee"] and from.distance_to(hit["position"]) > MELEE_RANGE:
		return
	var dmg := int(w["damage"])
	if pellets > 1:
		dmg = int(ceil(float(w["damage"]) / float(pellets)))
	body.receive_damage.rpc_id(body.get_multiplayer_authority(), dmg)

func _populate_option(opt: OptionButton, slot: String) -> void:
	if opt == null:
		return
	opt.clear()
	for id in WEAPONS:
		if WEAPONS[id]["slot"] != slot:
			continue
		opt.add_item(WEAPONS[id]["name"])
		var idx := opt.item_count - 1
		opt.set_item_metadata(idx, id)
		if id == loadout[slot]:
			opt.select(idx)
	opt.item_selected.connect(_on_loadout_option_selected.bind(opt, slot))

func _on_loadout_option_selected(idx: int, opt: OptionButton, slot: String) -> void:
	loadout[slot] = opt.get_item_metadata(idx)
	if current_slot == slot:
		_set_slot(slot)

func _set_current_weapon_id(id: String) -> void:
	current_weapon_id = id
	if id != "sniper":
		_set_scoped(false)
	_build_weapon_model()
	_update_weapon_label()

func _build_weapon_model() -> void:
	if weapon_model_root == null:
		return
	for c in weapon_model_root.get_children():
		c.queue_free()
	var parts: Array = MODELS.get(current_weapon_id, MODELS["pistol"])
	for part in parts:
		weapon_model_root.add_child(_make_part(part))

func _make_part(part: Dictionary) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh
	match part.get("t", "box"):
		"cyl":
			mesh = CylinderMesh.new()
			mesh.top_radius = part["s"].x
			mesh.bottom_radius = part["s"].x
			mesh.height = part["s"].y
		"torus":
			mesh = TorusMesh.new()
			mesh.inner_radius = part["s"].x
			mesh.outer_radius = part["s"].y
		_:
			mesh = BoxMesh.new()
			mesh.size = part["s"]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = part.get("c", Color(0.5, 0.5, 0.5))
	mat.metallic = 0.35
	mat.roughness = 0.55
	mesh.material = mat
	mi.mesh = mesh
	mi.position = part.get("p", Vector3.ZERO)
	if part.has("r"):
		mi.rotation_degrees = part["r"]
	return mi

func _update_weapon_label() -> void:
	if not is_multiplayer_authority() or not is_instance_valid(weapon_label):
		return
	var w := _current_weapon()
	var t: String = w["name"]
	if _reloading:
		t += "   [RELOADING]"
	elif int(w.get("mag", 0)) > 0:
		t += "   %d / %d" % [_ammo_for(current_weapon_id), int(w["mag"])]
	weapon_label.text = t

func _play_sound(name: String) -> void:
	if weapon_audio == null:
		return
	var s = load("res://sfx/%s.wav" % name)
	if s == null:
		return
	weapon_audio.stream = s
	weapon_audio.play()

# --- Colour -----------------------------------------------------------------

func _set_player_color(c: Color) -> void:
	player_color = c
	_apply_color()

func _set_player_name(v: String) -> void:
	player_name = v
	if name_tag != null:
		name_tag.text = v

func _apply_color() -> void:
	if body_mesh == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = player_color
	body_mesh.material_override = mat

# --- Surf mode ------------------------------------------------------------------

func _set_surf_mode(v: bool) -> void:
	surf_mode = v
	if is_inside_tree():
		floor_max_angle = deg_to_rad(SURF_FLOOR_MAX_ANGLE_DEG if v else 45.0)

# --- Networking hooks -----------------------------------------------------------

@rpc("call_local")
func play_shoot_effects(sfx: String = "", is_melee: bool = false):
	anim_player.stop()
	anim_player.play("shoot")
	if not is_melee:
		muzzle_flash.restart()
		muzzle_flash.emitting = true
	if sfx != "":
		_play_sound(sfx)

@rpc("any_peer", "reliable")
func receive_damage(amount: int = 1):
	health -= amount
	if health <= 0:
		health = MAX_HEALTH
		velocity = Vector3.ZERO
		position = _fresh_spawn()
		_ammo.clear()
		_reloading = false
		_set_scoped(false)
		_update_weapon_label()
	health_changed.emit(health)

func _fresh_spawn() -> Vector3:
	var w = get_parent()
	if w != null and w.has_method("get_spawn_point"):
		var p: Vector3 = w.get_spawn_point()
		return p
	return spawn_position

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle")
