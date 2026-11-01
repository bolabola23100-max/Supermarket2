
extends Control

@onready var base = $JoystickBase
@onready var knob = $JoystickBase/JoystickKnob

var direction := Vector2.ZERO
var is_pressed := false
var touch_index := -1

const MAX_DISTANCE := 60.0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reset_joystick()

func _gui_input(event):

	# لمس الشاشة
	if event is InputEventScreenTouch:
		if event.pressed and not is_pressed:
			is_pressed = true
			touch_index = event.index
			direction = Vector2.ZERO

		elif not event.pressed and event.index == touch_index:
			reset_joystick()

	# سحب الإصبع
	elif event is InputEventScreenDrag:
		if is_pressed and event.index == touch_index:
			update_joystick(event.position)

	# ضغط الماوس للاختبار
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_pressed = true
				direction = Vector2.ZERO
			else:
				reset_joystick()

	# تحريك الماوس
	elif event is InputEventMouseMotion and is_pressed:
		update_joystick(event.position)


func update_joystick(position: Vector2):
	var center = base.position + base.size / 2
	var offset = position - center

	offset = offset.limit_length(MAX_DISTANCE)

	knob.position = center + offset - knob.size / 2
	direction = offset / MAX_DISTANCE


func reset_joystick():
	direction = Vector2.ZERO
	is_pressed = false
	touch_index = -1
	knob.position = (base.size - knob.size) / 2
