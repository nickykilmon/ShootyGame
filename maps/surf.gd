extends Node3D

# CS-style surf map: four ramps down a long course, alternating right / left /
# right / left. You ride the face of one ramp, slide/launch off its lower end,
# air-strafe across the gap, and catch the next ramp on the opposite side.
#
# The ramps are rolled steeper than Player.gd's floor_max_angle (45 deg) so
# is_on_floor() stays false on them -> air physics (no friction + air-strafe
# accel) -> surf.
#
# ResetZone is a big Area3D under the course; falling off teleports you to Spawn.

# --- Tuning knob -----------------------------------------------------------
# Roll of each ramp face, in degrees. Player.gd lowers floor_max_angle to ~25 in
# surf mode, so gentle ramps here still read as "not floor" (frictionless slide).
# Lower = mellower, more forgiving. 30-45 is the useful range.
const RAMP_ROLL_DEG := 34.0

@onready var _spawns: Node3D = $Spawns

func _ready() -> void:
	# Right-side ramps (+X): surf leaning left, strafe with D + mouse right.
	# Left-side ramps (-X):  surf leaning right, strafe with A + mouse left.
	$Ramp1.rotation_degrees.z = RAMP_ROLL_DEG
	$Ramp2.rotation_degrees.z = -RAMP_ROLL_DEG
	$Ramp3.rotation_degrees.z = RAMP_ROLL_DEG
	$Ramp4.rotation_degrees.z = -RAMP_ROLL_DEG
	$ResetZone.body_entered.connect(_on_reset_zone_body_entered)

func _on_reset_zone_body_entered(body: Node3D) -> void:
	# Only reset the player this peer actually controls, so we don't fight the
	# MultiplayerSynchronizer over remote players' positions.
	if body is CharacterBody3D and body.is_multiplayer_authority():
		body.velocity = Vector3.ZERO
		var kids := _spawns.get_children()
		var m: Node3D = kids[randi() % kids.size()]
		body.global_position = m.global_position + Vector3(
			randf_range(-1.5, 1.5), 0.0, randf_range(-1.5, 1.5))
