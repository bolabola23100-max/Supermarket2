extends Node3D

@onready var screen: MeshInstance3D = $Screen
@onready var computer_viewport: SubViewport = $ComputerViewport
@onready var camera_point: Marker3D = $ComputerCameraPoint

var player: Node3D
var camera: Camera3D
var exit_computer_button: Button


var original_camera_transform: Transform3D
var camera_tween: Tween
var was_in_computer_mode := false


func _ready():
	# إعداد شاشة الكمبيوتر
	var screen_material = StandardMaterial3D.new()
	screen_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen_material.albedo_texture = computer_viewport.get_texture()
	screen.material_override = screen_material

	# العثور على اللاعب والكاميرا
	player = get_tree().get_first_node_in_group("player")

	if player != null:
		camera = player.get_node("Camera3D")

	# العثور على زر الخروج
	exit_computer_button = get_tree().current_scene.find_child(
		"ExitComputerButton", true, false
	)

	if exit_computer_button:
		exit_computer_button.hide()
		exit_computer_button.pressed.connect(_on_exit_computer_pressed)
	else:
		push_warning("ExitComputerButton not found!")


func _process(_delta):
	if player == null or camera == null:
		return

	# إظهار زر الخروج أثناء استخدام الكمبيوتر
	if exit_computer_button:
		exit_computer_button.visible = player.in_computer_mode

	# اكتشاف الدخول والخروج من وضع الكمبيوتر
	if player.in_computer_mode and not was_in_computer_mode:
		enter_computer_camera()

	elif not player.in_computer_mode and was_in_computer_mode:
		exit_computer_camera()

	was_in_computer_mode = player.in_computer_mode


# =========================
# CAMERA MOVEMENT
# =========================

func enter_computer_camera():
	# حفظ مكان الكاميرا الأصلي
	original_camera_transform = camera.global_transform

	if camera_tween and camera_tween.is_running():
		camera_tween.kill()

	camera_tween = create_tween()
	camera_tween.set_trans(Tween.TRANS_SINE)
	camera_tween.set_ease(Tween.EASE_IN_OUT)

	camera_tween.tween_property(
		camera,
		"global_transform",
		camera_point.global_transform,
		0.8
	)

	print("CAMERA MOVING TO COMPUTER")


func exit_computer_camera():
	if camera_tween and camera_tween.is_running():
		camera_tween.kill()

	camera_tween = create_tween()
	camera_tween.set_trans(Tween.TRANS_SINE)
	camera_tween.set_ease(Tween.EASE_IN_OUT)

	camera_tween.tween_property(
		camera,
		"global_transform",
		original_camera_transform,
		0.8
	)

	print("CAMERA RETURNING")


# =========================
# EXIT COMPUTER BUTTON
# =========================

func _on_exit_computer_pressed():
	if player != null:
		player.exit_computer_mode()


# =========================
# COMPUTER SCREEN INPUT
# =========================

func _unhandled_input(event):
	if player == null or camera == null:
		return

	if not player.in_computer_mode:
		return

	if event is InputEventScreenTouch:
		send_click_to_screen(event.position, event.pressed)
		get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag:
		get_viewport().set_input_as_handled()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			send_click_to_screen(event.position, event.pressed)

		get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()


func send_click_to_screen(pointer_position: Vector2, pressed: bool):

	# إنشاء شعاع من الكاميرا
	var ray_origin = camera.project_ray_origin(pointer_position)
	var ray_direction = camera.project_ray_normal(pointer_position)

	# تحديد مستوى شاشة الكمبيوتر
	var screen_normal = screen.global_transform.basis.z.normalized()
	var screen_plane = Plane(screen_normal, screen.global_position)

	var hit = screen_plane.intersects_ray(
		ray_origin,
		ray_direction
	)

	if hit == null:
		return

	# تحويل نقطة الاصطدام إلى إحداثيات محلية
	var local_hit = screen.to_local(hit)

	# تحويل الإحداثيات إلى UV
	var actual_size: Vector2 = screen.mesh.size

	var uv_x = (local_hit.x / actual_size.x) + 0.5
	var uv_y = 0.5 - (local_hit.y / actual_size.y)
	# التأكد أن اللمس داخل الشاشة
	if uv_x < 0.0 or uv_x > 1.0:
		return

	if uv_y < 0.0 or uv_y > 1.0:
		return

	# تحويل الإحداثيات إلى SubViewport
	var viewport_position = Vector2(
		uv_x * computer_viewport.size.x,
		uv_y * computer_viewport.size.y
	)

	# إرسال ضغطة الماوس إلى واجهة الكمبيوتر
	var touch_event = InputEventMouseButton.new()
	touch_event.button_index = MOUSE_BUTTON_LEFT
	touch_event.pressed = pressed
	touch_event.position = viewport_position

	computer_viewport.push_input(touch_event)
	get_viewport().set_input_as_handled()
