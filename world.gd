extends Node

@onready var main_menu = $CanvasLayer/MainMenu
@onready var name_entry: LineEdit = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/NameEntry
@onready var code_entry: LineEdit = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/CodeEntry
@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar
@onready var code_label = $CanvasLayer/HUD/CodeLabel
@onready var map_select = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/MapSelect
@onready var color_picker = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/ColorPicker
@onready var map_root = $Map
@onready var chat_log: RichTextLabel = $CanvasLayer/HUD/ChatLog
@onready var chat_input: LineEdit = $CanvasLayer/HUD/ChatInput
@onready var lb_rows = $CanvasLayer/HUD/Leaderboard/Margin/Rows
@onready var locker = $CanvasLayer/Locker
@onready var locker_btn = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/LockerButton
@onready var skin_opt: OptionButton = $CanvasLayer/Locker/M/V/SkinRow/Opt
@onready var head_opt: OptionButton = $CanvasLayer/Locker/M/V/HeadRow/Opt
@onready var face_opt: OptionButton = $CanvasLayer/Locker/M/V/FaceRow/Opt
@onready var hair_opt: OptionButton = $CanvasLayer/Locker/M/V/HairRow/Opt
@onready var back_opt: OptionButton = $CanvasLayer/Locker/M/V/BackRow/Opt
@onready var case_btn: Button = $CanvasLayer/Locker/M/V/CaseButton
@onready var case_result: RichTextLabel = $CanvasLayer/Locker/M/V/Result
@onready var locker_close: Button = $CanvasLayer/Locker/M/V/CloseButton
@onready var status_label: Label = $CanvasLayer/Status


const Player = preload("res://player.tscn")
# Index matches the MapSelect OptionButton items ("Arena" = 0, "Surf" = 1)
# and the MapSpawner's _spawnable_scenes list.
const MAPS := ["res://maps/arena.tscn", "res://maps/surf.tscn"]
const PORT = 9999
# Crockford-ish base32: no I, L, O, U so codes can't be misread off the screen.
const _B32 := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

# Browsers can't do UDP, so the web build talks WebSocket to a dedicated server.
# Fallback address, used only if the live lookup below fails.
const WEB_SERVER_URL := "wss://fps-server-0tuv.onrender.com"

# The web build fetches the CURRENT server address from this file at join time,
# so you can change servers by editing one line + pushing (no re-export needed).
const SERVER_CONFIG_URL := "https://raw.githubusercontent.com/nickykilmon/ShootyGame/main/server.txt"

var enet_peer = ENetMultiplayerPeer.new()

# This peer's own picks from the Host/Join screen. Player.gd reads local_color /
# local_name off its parent (this node) when it spawns.
var local_color := Color(1, 1, 1)
var local_name := "Player"
var local_skin := ""
var local_cos := {"head": "", "face": "", "hair": "", "back": ""}
var surf_selected := false

# Connection state
var _connecting := false
var _connect_deadline := 0.0
var _target := {}

const CASE_COOLDOWN := 72000   # 20 hours (seconds)

# Live match scores, kept on the server: { peer_id : {"k": kills, "d": deaths} }
var scores := {}
var _my_last_kills := 0
var _my_last_deaths := 0
var _chat_lines := []

# Per-player profile that survives leaving/returning (web: user:// -> IndexedDB).
# Foundation for daily cases / skins later.
const PROFILE_PATH := "user://profile.json"
var profile := {
	"name": "",
	"lifetime_kills": 0,
	"lifetime_deaths": 0,
	"last_case": 0,
	"inventory": [],
	"equipped_skin": "",
	"equipped_cos": {"head": "", "face": "", "hair": "", "back": ""},
}

func _ready():
	if _is_dedicated_server():
		_run_dedicated_server()
		return

	_load_profile()
	if profile.get("name", "") != "":
		name_entry.text = str(profile["name"])
	chat_input.hide()
	chat_input.text_submitted.connect(_on_chat_submitted)
	_render_leaderboard([])

	status_label.hide()
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	locker.hide()
	locker_btn.pressed.connect(_open_locker)
	locker_close.pressed.connect(func(): locker.hide())
	case_btn.pressed.connect(_on_case_pressed)
	skin_opt.item_selected.connect(func(i): _equip_from(skin_opt, i, "skin", ""))
	head_opt.item_selected.connect(func(i): _equip_from(head_opt, i, "cos", "head"))
	face_opt.item_selected.connect(func(i): _equip_from(face_opt, i, "cos", "face"))
	hair_opt.item_selected.connect(func(i): _equip_from(hair_opt, i, "cos", "hair"))
	back_opt.item_selected.connect(func(i): _equip_from(back_opt, i, "cos", "back"))

	if OS.has_feature("web"):
		# Web clients can only join the shared server - hide the host-only bits.
		map_select.hide()
		code_entry.hide()
		var host_btn = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/HostButton
		if host_btn:
			host_btn.hide()

func _unhandled_input(_event):
	pass

func _process(_delta):
	# Hard timeout: if we somehow never got connected_to_server or connection_failed.
	if _connecting and Time.get_unix_time_from_system() > _connect_deadline:
		_abort_connect("Couldn't reach the server. It may be asleep - wait a minute and try again.")

func _input(event):
	if _connecting and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_abort_connect("Cancelled.")
		get_viewport().set_input_as_handled()
		return
	if not hud.visible:
		return
	if chat_input.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_chat()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
		chat_input.show()
		chat_input.grab_focus()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()

func _on_chat_submitted(text: String) -> void:
	text = text.strip_edges()
	if text != "":
		net_say.rpc_id(1, text)
	_close_chat()

func _close_chat() -> void:
	chat_input.text = ""
	chat_input.hide()
	chat_input.release_focus()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# --- Chat + kill feed --------------------------------------------------------

@rpc("any_peer", "reliable")
func net_say(text: String) -> void:
	if not multiplayer.is_server():
		return
	text = text.strip_edges().replace("[", "(").replace("]", ")")
	if text == "" or text.length() > 120:
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender == 0:
		sender = multiplayer.get_unique_id()
	push_line.rpc("[color=#e8e8e8]%s:[/color] %s" % [_name_for(sender), text])

@rpc("authority", "call_local", "reliable")
func push_line(bb: String) -> void:
	_chat_lines.append(bb)
	if _chat_lines.size() > 9:
		_chat_lines = _chat_lines.slice(_chat_lines.size() - 9)
	if chat_log:
		chat_log.text = "\n".join(PackedStringArray(_chat_lines))

@rpc("any_peer", "reliable")
func report_death(killer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var victim := multiplayer.get_remote_sender_id()
	if victim == 0:
		victim = multiplayer.get_unique_id()
	_ensure_score(victim)
	scores[victim]["d"] += 1
	if killer_id != 0 and killer_id != victim:
		_ensure_score(killer_id)
		scores[killer_id]["k"] += 1
		push_line.rpc("[color=#ff7a7a]%s[/color]  killed  [color=#8fbcff]%s[/color]" % [_name_for(killer_id), _name_for(victim)])
	else:
		push_line.rpc("[color=#999999]%s died[/color]" % _name_for(victim))
	sync_scores.rpc(_scores_payload())

@rpc("authority", "call_local", "reliable")
func sync_scores(rows: Array) -> void:
	_render_leaderboard(rows)
	var me := multiplayer.get_unique_id()
	for r in rows:
		if r.size() >= 4 and int(r[3]) == me:
			var k := int(r[1])
			var d := int(r[2])
			if k > _my_last_kills:
				profile["lifetime_kills"] = int(profile.get("lifetime_kills", 0)) + (k - _my_last_kills)
			if d > _my_last_deaths:
				profile["lifetime_deaths"] = int(profile.get("lifetime_deaths", 0)) + (d - _my_last_deaths)
			_my_last_kills = k
			_my_last_deaths = d
			_save_profile()

func _ensure_score(id: int) -> void:
	if id != 0 and not scores.has(id):
		scores[id] = {"k": 0, "d": 0}

func _name_for(id: int) -> String:
	var p = get_node_or_null(str(id))
	if p != null and "player_name" in p and str(p.player_name) != "":
		return str(p.player_name)
	return "Player " + str(id)

func _scores_payload() -> Array:
	var rows := []
	for id in scores:
		rows.append([_name_for(id), scores[id]["k"], scores[id]["d"], id])
	rows.sort_custom(func(a, b): return int(a[1]) > int(b[1]))
	return rows

func _render_leaderboard(rows: Array) -> void:
	if lb_rows == null:
		return
	for c in lb_rows.get_children():
		if c.name != "Title":
			c.queue_free()
	for r in rows:
		var l := Label.new()
		l.text = "%s   %d / %d" % [str(r[0]), int(r[1]), int(r[2])]
		lb_rows.add_child(l)

# --- Profile persistence ---------------------------------------------------

func _load_profile() -> void:
	if not FileAccess.file_exists(PROFILE_PATH):
		return
	var f := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) == TYPE_DICTIONARY:
		for k in d:
			profile[k] = d[k]

func _save_profile() -> void:
	var f := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(profile))

# --- Locker + daily case --------------------------------------------------

func _open_locker() -> void:
	var unlocked := _check_secret()
	_refresh_locker()
	if unlocked:
		case_result.text = "[center][color=#8fffa0][b]Everything unlocked![/b][/color][/center]"
	locker.show()

func _refresh_locker() -> void:
	var inv: Array = profile.get("inventory", [])
	_fill_opt(skin_opt, "Default", _owned_skins(inv), str(profile.get("equipped_skin", "")))
	var ec = profile.get("equipped_cos", {})
	_fill_opt(head_opt, "None", _owned_cos(inv, "head"), str(ec.get("head", "")))
	_fill_opt(face_opt, "None", _owned_cos(inv, "face"), str(ec.get("face", "")))
	_fill_opt(hair_opt, "None", _owned_cos(inv, "hair"), str(ec.get("hair", "")))
	_fill_opt(back_opt, "None", _owned_cos(inv, "back"), str(ec.get("back", "")))
	if _can_open_case():
		case_btn.disabled = false
		case_btn.text = "Open Daily Case  (ready!)"
	else:
		case_btn.disabled = true
		var left := CASE_COOLDOWN - int(Time.get_unix_time_from_system() - int(profile.get("last_case", 0)))
		case_btn.text = "Next case in %dh %dm" % [left / 3600, (left % 3600) / 60]

func _owned_skins(inv: Array) -> Array:
	var out := []
	for id in inv:
		if Cosmetics.SKINS.has(id):
			out.append(id)
	return out

func _owned_cos(inv: Array, slot: String) -> Array:
	var out := []
	for id in inv:
		if Cosmetics.COSMETICS.has(id) and Cosmetics.COSMETICS[id]["slot"] == slot:
			out.append(id)
	return out

func _fill_opt(opt: OptionButton, none_text: String, ids: Array, equipped: String) -> void:
	opt.clear()
	opt.add_item(none_text)
	opt.set_item_metadata(0, "")
	for id in ids:
		opt.add_item(Cosmetics.item(id).get("name", id))
		opt.set_item_metadata(opt.item_count - 1, id)
		if id == equipped:
			opt.select(opt.item_count - 1)

func _equip_from(opt: OptionButton, idx: int, kind: String, slot: String) -> void:
	var id: String = str(opt.get_item_metadata(idx))
	if kind == "skin":
		profile["equipped_skin"] = id
	else:
		var ec: Dictionary = profile.get("equipped_cos", {})
		ec[slot] = id
		profile["equipped_cos"] = ec
	_save_profile()

func _can_open_case() -> bool:
	return Time.get_unix_time_from_system() - float(profile.get("last_case", 0)) >= CASE_COOLDOWN

func _on_case_pressed() -> void:
	if not _can_open_case():
		return
	profile["last_case"] = int(Time.get_unix_time_from_system())
	var rarity := Cosmetics.roll_rarity(randf())
	var pool: Array = Cosmetics.ids_of_rarity(rarity)
	if pool.is_empty():
		pool = Cosmetics.ids_of_rarity("common")
	var inv: Array = profile.get("inventory", [])
	var got: String = pool[randi() % pool.size()]
	for _i in 4:                       # try to land on something you don't own yet
		var cand: String = pool[randi() % pool.size()]
		got = cand
		if not inv.has(cand):
			break
	var dupe := inv.has(got)
	if not dupe:
		inv.append(got)
	profile["inventory"] = inv
	_save_profile()
	var it := Cosmetics.item(got)
	var col: Color = Cosmetics.RARITY_COLOR.get(it.get("rarity", "common"), Color.WHITE)
	case_result.text = "[center][color=#%s][b]%s[/b]  -  %s[/color]%s[/center]" % [
		col.to_html(false),
		str(it.get("rarity", "")).to_upper(),
		str(it.get("name", got)),
		"\n[color=#888888](duplicate)[/color]" if dupe else "",
	]
	_refresh_locker()

func _is_dedicated_server() -> bool:
	return OS.has_feature("dedicated_server") \
		or OS.get_cmdline_args().has("--server") \
		or OS.get_cmdline_user_args().has("--server")

# Headless mode: launched with `--server`. Creates the WebSocket server, loads a
# map, and waits for clients. No local player, no menu, no HUD.
func _run_dedicated_server() -> void:
	main_menu.hide()
	# Some hosts inject the port to bind via the PORT env var.
	var bind_port := PORT
	if OS.has_environment("PORT") and OS.get_environment("PORT").is_valid_int():
		bind_port = int(OS.get_environment("PORT"))
	var peer := WebSocketMultiplayerPeer.new()
	var err := peer.create_server(bind_port)
	if err != OK:
		push_error("Dedicated server failed to start: %d" % err)
		get_tree().quit(1)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.server_relay = true   # relay sync/RPC packets between clients
	multiplayer.peer_connected.connect(func(id): print("[server] peer connected: ", id))
	multiplayer.peer_disconnected.connect(func(id): print("[server] peer disconnected: ", id))
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	var wants_surf := OS.get_cmdline_user_args().has("--map=surf") \
		or OS.get_cmdline_args().has("--map=surf")
	_load_map(1 if wants_surf else 0)
	print("Dedicated WebSocket server listening on port %d" % bind_port)

const SECRET_CODE := "NicksSecretCode"

# Type the secret code into the name box -> unlock everything. Returns true if it fired.
func _check_secret() -> bool:
	if name_entry.text.strip_edges() != SECRET_CODE:
		return false
	profile["inventory"] = Cosmetics.all_ids().duplicate()
	name_entry.text = str(profile.get("name", ""))
	_save_profile()
	return true

func _set_local_prefs() -> void:
	_check_secret()
	local_color = color_picker.color
	local_name = name_entry.text.strip_edges()
	if local_name == "":
		local_name = "Player%d" % (randi() % 1000)
	local_skin = str(profile.get("equipped_skin", ""))
	var ec = profile.get("equipped_cos", {})
	local_cos = {
		"head": str(ec.get("head", "")),
		"face": str(ec.get("face", "")),
		"hair": str(ec.get("hair", "")),
		"back": str(ec.get("back", "")),
	}
	profile["name"] = local_name
	_save_profile()

func _on_host_button_pressed():
	if OS.has_feature("web"):
		return   # a browser tab can't accept incoming connections
	_set_local_prefs()
	main_menu.hide()
	hud.show()

	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)

	# Spawn the chosen map. MapSpawner replicates it to every client that joins.
	_load_map(map_select.selected)
	add_player(multiplayer.get_unique_id())

	# Build the room code from our address so friends can join with just the code.
	# (upnp_setup can block ~2s while it probes the router.)
	var ip := upnp_setup()
	if ip.split(".").size() != 4:   # blank, or an IPv6 / hostname - unusable
		ip = _local_ipv4()
	var code := _encode_code(ip, PORT)
	code_label.text = "ROOM CODE:  %s" % code
	code_label.show()
	print("Room code: %s   (host address %s:%d)" % [code, ip, PORT])

func _on_join_button_pressed():
	if _connecting:
		return
	_set_local_prefs()

	if OS.has_feature("web"):
		_connecting = true
		_connect_deadline = Time.get_unix_time_from_system() + 110.0
		_show_status("Finding server...")
		var url := await _fetch_server_url()
		if not _connecting:
			return
		_target = {"web": true, "url": url}
		_show_status("Connecting to the server...\n(the server can take up to a minute to wake up - hang tight)")
		_try_connect()
		return
	else:
		# Desktop: blank code -> localhost. Otherwise decode the room code.
		var ip := "127.0.0.1"
		var port := PORT
		var raw := code_entry.text.strip_edges()
		if raw != "":
			var info := _decode_code(raw)
			if info.is_empty():
				code_entry.text = ""
				code_entry.placeholder_text = "Invalid code - try again"
				return
			ip = info["ip"]
			port = int(info["port"])
		_target = {"web": false, "ip": ip, "port": port}

	_connecting = true
	_connect_deadline = Time.get_unix_time_from_system() + 100.0
	_show_status("Connecting to the server...\n(the free server can take up to a minute to wake up - hang tight)")
	_try_connect()

func _try_connect() -> void:
	if not _connecting:
		return
	var peer
	if _target.get("web", false):
		peer = WebSocketMultiplayerPeer.new()
		peer.create_client(str(_target.get("url", WEB_SERVER_URL)))
	else:
		peer = ENetMultiplayerPeer.new()
		peer.create_client(_target["ip"], int(_target["port"]))
	multiplayer.multiplayer_peer = peer

func _fetch_server_url() -> String:
	var req := HTTPRequest.new()
	req.timeout = 8.0
	add_child(req)
	if req.request(SERVER_CONFIG_URL) != OK:
		req.queue_free()
		return WEB_SERVER_URL
	var res = await req.request_completed
	req.queue_free()
	# res = [result, response_code, headers, body]
	if int(res[1]) == 200:
		var txt := (res[3] as PackedByteArray).get_string_from_utf8().strip_edges()
		# take the first non-empty, non-comment line
		for line in txt.split("\n"):
			line = line.strip_edges()
			if line.begins_with("wss://") or line.begins_with("ws://"):
				return line
	return WEB_SERVER_URL

func _on_connected_to_server() -> void:
	_connecting = false
	_hide_status()
	main_menu.hide()
	hud.show()

func _on_connection_failed() -> void:
	if not _connecting:
		return
	multiplayer.multiplayer_peer = null
	if Time.get_unix_time_from_system() < _connect_deadline:
		await get_tree().create_timer(3.0).timeout
		_try_connect()
	else:
		_abort_connect("Couldn't reach the server. It may be asleep - wait a minute and try again.")

func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	_connecting = false
	hud.hide()
	_show_status("Lost connection to the server.")
	await get_tree().create_timer(2.5).timeout
	_hide_status()
	main_menu.show()

func _abort_connect(msg: String) -> void:
	_connecting = false
	multiplayer.multiplayer_peer = null
	_show_status(msg)
	await get_tree().create_timer(3.0).timeout
	_hide_status()
	main_menu.show()

func _show_status(msg: String) -> void:
	status_label.text = msg
	status_label.show()

func _hide_status() -> void:
	status_label.hide()

func add_player(peer_id):
	print("[add_player] spawning player for peer ", peer_id)
	var player = Player.instantiate()
	player.name = str(peer_id)
	var spawn_pos := get_spawn_point()
	player.position = spawn_pos
	player.spawn_position = spawn_pos
	player.surf_mode = surf_selected
	add_child(player)
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)
	if multiplayer.is_server():
		_ensure_score(int(peer_id))
		# give the name a moment to replicate, then broadcast the board
		get_tree().create_timer(0.5).timeout.connect(func():
			if scores.has(int(peer_id)):
				sync_scores.rpc(_scores_payload()))

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		if multiplayer.is_server():
			push_line.rpc("[color=#999999]%s left[/color]" % _name_for(int(peer_id)))
		player.queue_free()
	if multiplayer.is_server():
		scores.erase(int(peer_id))
		sync_scores.rpc(_scores_payload())

# Instances the selected map under $Map. Only the host calls this; the
# MapSpawner then recreates the same scene on every client (including late joiners).
func _load_map(index: int) -> void:
	surf_selected = (index == 1)
	for child in map_root.get_children():
		child.queue_free()
	var path: String = MAPS[clampi(index, 0, MAPS.size() - 1)]
	var map: Node = load(path).instantiate()
	map.name = "CurrentMap"
	map_root.add_child(map)

# Picks a spawn from the current map, preferring the one farthest from every
# player that's currently alive (so you don't drop in on top of a fight).
# Also called by Player.gd on death respawn.
func get_spawn_point() -> Vector3:
	var map = map_root.get_node_or_null("CurrentMap")
	if map == null:
		return Vector3.ZERO

	var markers := []
	var container = map.get_node_or_null("Spawns")
	if container != null:
		for c in container.get_children():
			markers.append(c)
	elif map.has_node("Spawn"):
		markers.append(map.get_node("Spawn"))
	if markers.is_empty():
		return Vector3.ZERO

	markers.shuffle()
	var players = get_tree().get_nodes_in_group("players")
	var best = null
	var best_score := -1.0
	for m in markers:
		var mp: Vector3 = m.global_position
		if not _is_clear(mp):
			continue   # a pillar / wall is here - skip it
		var nearest := 1.0e9
		for p in players:
			nearest = minf(nearest, mp.distance_to(p.global_position))
		if players.is_empty():
			nearest = randf()
		if nearest > best_score:
			best_score = nearest
			best = m
	var chosen = best if best != null else markers[0]
	# spawn a bit above the marker so a slight overlap drops you out instead of trapping you
	var bp: Vector3 = chosen.global_position + Vector3.UP * 1.5
	return bp + Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))

# True if a player-sized capsule at pos doesn't overlap any solid geometry.
func _is_clear(pos: Vector3) -> bool:
	var vp := get_viewport()
	if vp == null or vp.find_world_3d() == null:
		return true
	var space := vp.find_world_3d().direct_space_state
	if space == null:
		return true
	var q := PhysicsShapeQueryParameters3D.new()
	var sh := CapsuleShape3D.new()
	sh.radius = 0.5
	sh.height = 1.8
	q.shape = sh
	q.transform = Transform3D(Basis(), pos + Vector3.UP * 1.1)
	q.collision_mask = 1
	return space.intersect_shape(q, 1).is_empty()

func update_health_bar(health_value):
	health_bar.value = health_value

func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)

# --- Room code (packs IPv4 + port into a short base-36 string) ----------------

func _encode_code(ip: String, port: int) -> String:
	var parts := ip.split(".")
	if parts.size() != 4:
		return ""
	var n := 0
	for p in parts:
		n = n * 256 + int(p)
	n = n * 65536 + port
	var s := ""
	while n > 0:
		s = _B32[n % 32] + s
		n = int(n / 32)
	return s if s != "" else "0"

func _decode_code(code: String) -> Dictionary:
	# Be forgiving: accept the whole label, lower case, spaces, dashes, and the
	# usual look-alike swaps.
	code = code.to_upper().strip_edges()
	code = code.trim_prefix("ROOM CODE:").trim_prefix("ROOM CODE").strip_edges()
	code = code.replace(" ", "").replace("-", "").replace("_", "")
	code = code.replace("I", "1").replace("L", "1").replace("O", "0")
	if code.is_empty() or code.length() > 13:
		return {}
	var n := 0
	for ch in code:
		var d := _B32.find(ch)
		if d < 0:
			return {}
		n = n * 32 + d
	var port := n % 65536
	n = int(n / 65536)
	var d4 := n % 256; n = int(n / 256)
	var d3 := n % 256; n = int(n / 256)
	var d2 := n % 256; n = int(n / 256)
	var d1 := n % 256
	if d1 == 0:
		return {}
	return {"ip": "%d.%d.%d.%d" % [d1, d2, d3, d4], "port": port}

func _local_ipv4() -> String:
	for addr in IP.get_local_addresses():
		if addr.count(".") == 3 and not addr.begins_with("127.") and not addr.begins_with("169.254."):
			return addr
	return "127.0.0.1"

# Tries to open the port on the router. Returns the public IP on success, "" otherwise.
func upnp_setup() -> String:
	var upnp := UPNP.new()
	if upnp.discover() != UPNP.UPNP_RESULT_SUCCESS:
		return ""
	var gateway = upnp.get_gateway()
	if gateway == null or not gateway.is_valid_gateway():
		return ""
	if upnp.add_port_mapping(PORT) != UPNP.UPNP_RESULT_SUCCESS:
		return ""
	var ext: String = upnp.query_external_address()
	print("UPNP ok - external address %s" % ext)
	return ext
