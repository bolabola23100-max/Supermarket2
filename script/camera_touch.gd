
extends Control

@export var sensitivity: float = 0.15
@export var min_look_angle: float = -80.0
@export var max_look_angle: float = 80.0

@onready var player = $"../../Player"
@onready var camera = $"../../Player/Camera3D"

var active_touch := -1
var mouse_looking := false

func _input(event):

	var screen_width = get_viewport_rect().size.x

	# بداية لمس الشاشة
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x > screen_width / 2 and active_touch == -1:
				active_touch = event.index
		elif event.index == active_touch:
			active_touch = -1

	# سحب الإصبع
	elif event is InputEventScreenDrag:
		if event.index == active_touch:
			rotate_camera(event.relative)

	# بداية السحب بالماوس للاختبار
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and event.position.x > screen_width / 2:
				mouse_looking = true
			else:
				mouse_looking = false

	# تحريك الماوس
	elif event is InputEventMouseMotion and mouse_looking:
		rotate_camera(event.relative)


func rotate_camera(movement: Vector2):
	player.rotation_degrees.y -= movement.x * sensitivity

	camera.rotation_degrees.x -= movement.y * sensitivity
	camera.rotation_degrees.x = clamp(
		camera.rotation_degrees.x,
		min_look_angle,
		max_look_angle
	)
