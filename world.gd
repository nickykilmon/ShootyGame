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


const Player = preload("res://player.tscn")
# Index matches the MapSelect OptionButton items ("Arena" = 0, "Surf" = 1)
# and the MapSpawner's _spawnable_scenes list.
const MAPS := ["res://maps/arena.tscn", "res://maps/surf.tscn"]
const PORT = 9999
# Crockford-ish base32: no I, L, O, U so codes can't be misread off the screen.
const _B32 := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

# Browsers can't do UDP, so the web build talks WebSocket to a dedicated server.
# >>> After you deploy the server (see the deploy guide), put its address here. <<<
const WEB_SERVER_URL := "wss://fps-server-0tuv.onrender.com"

var enet_peer = ENetMultiplayerPeer.new()

# This peer's own picks from the Host/Join screen. Player.gd reads local_color /
# local_name off its parent (this node) when it spawns.
var local_color := Color(1, 1, 1)
var local_name := "Player"
var surf_selected := false

func _ready():
	if _is_dedicated_server():
		_run_dedicated_server()
	elif OS.has_feature("web"):
		# Web clients can only join the shared server - hide the host-only bits.
		map_select.hide()
		code_entry.hide()
		var host_btn = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/HostButton
		if host_btn:
			host_btn.hide()

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

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
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	var wants_surf := OS.get_cmdline_user_args().has("--map=surf") \
		or OS.get_cmdline_args().has("--map=surf")
	_load_map(1 if wants_surf else 0)
	print("Dedicated WebSocket server listening on port %d" % bind_port)

func _set_local_prefs() -> void:
	local_color = color_picker.color
	local_name = name_entry.text.strip_edges()
	if local_name == "":
		local_name = "Player%d" % (randi() % 1000)

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
	# Web build: connect to the shared dedicated server over WebSocket.
	if OS.has_feature("web"):
		_set_local_prefs()
		main_menu.hide()
		hud.show()
		var wsp := WebSocketMultiplayerPeer.new()
		var werr := wsp.create_client(WEB_SERVER_URL)
		if werr != OK:
			push_error("WebSocket connect failed: %d" % werr)
		multiplayer.multiplayer_peer = wsp
		return

	# Desktop: blank code -> a host on this same machine (quick local testing).
	# Otherwise decode the room code.
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

	_set_local_prefs()
	main_menu.hide()
	hud.show()

	enet_peer.create_client(ip, port)
	multiplayer.multiplayer_peer = enet_peer

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	var spawn_pos := get_spawn_point()
	player.position = spawn_pos
	player.spawn_position = spawn_pos
	player.surf_mode = surf_selected
	add_child(player)
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

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
	var best = markers[0]
	var best_score := -1.0
	for m in markers:
		var mp: Vector3 = m.global_position
		var nearest := 1.0e9
		for p in players:
			nearest = minf(nearest, mp.distance_to(p.global_position))
		if players.is_empty():
			nearest = randf()
		if nearest > best_score:
			best_score = nearest
			best = m
	var bp: Vector3 = best.global_position
	return bp + Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))

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
