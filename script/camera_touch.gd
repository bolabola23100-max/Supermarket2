extends Control

@export var sensitivity: float = 0.15
@export var min_look_angle: float = -80.0
@export var max_look_angle: float = 80.0

@onready var player = $"../../Player"
@onready var camera = $"../../Player/Camera3D"

var active_touch := -1
var mouse_looking := false


func _input(event):

	# إيقاف تحريك الكاميرا أثناء الكمبيوتر
	if player.in_computer_mode:
		active_touch = -1
		mouse_looking = false
		return

	var screen_width = get_viewport_rect().size.x

	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x > screen_width / 2 and active_touch == -1:
				active_touch = event.index
		elif event.index == active_touch:
			active_touch = -1

	elif event is InputEventScreenDrag:
		if event.index == active_touch:
			rotate_camera(event.relative)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and event.position.x > screen_width / 2:
				mouse_looking = true
			else:
				mouse_looking = false

	elif event is InputEventMouseMotion and mouse_looking:
		rotate_camera(event.relative)


func rotate_camera(movement: Vector2):

	if player.in_computer_mode:
		return

	player.rotation_degrees.y -= movement.x * sensitivity

	camera.rotation_degrees.x -= movement.y * sensitivity
	camera.rotation_degrees.x = clamp(
		camera.rotation_degrees.x,
		min_look_angle,
		max_look_angle
	)
