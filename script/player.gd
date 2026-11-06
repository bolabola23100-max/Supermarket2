extends CharacterBody3D

@export var speed: float = 5.0
@export var gravity: float = 9.8

@onready var camera = $Camera3D
@onready var joystick = $"../MobileControls/Joystick"

@export var product_name: String = "Product"
@export var price: float = 10.0

var barcode_scanner: Area3D = null

# حالات اللاعب
var in_cashier_mode: bool = false
var in_computer_mode: bool = false


func _ready():
	add_to_group("player")

	collision_layer = 1
	collision_mask = 1 | 4

	barcode_scanner = get_tree().current_scene.find_child(
		"BarcodeScanner", true, false
	)


func _physics_process(delta):

	# قفل الحركة أثناء الكاشير أو الكمبيوتر
	if in_cashier_mode or in_computer_mode:

		velocity.x = 0.0
		velocity.z = 0.0

		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0.0

		move_and_slide()
		return

	# قراءة حركة الجويستيك
	var input_dir = joystick.direction

	if input_dir.length() < 0.1:
		input_dir = Input.get_vector(
			"move_left",
			"move_right",
			"move_forward",
			"move_backward"
		)

	# اتجاه الحركة حسب الكاميرا
	var forward = -camera.global_transform.basis.z
	var right = camera.global_transform.basis.x

	forward.y = 0
	right.y = 0

	forward = forward.normalized()
	right = right.normalized()

	var direction = right * input_dir.x + forward * -input_dir.y
	direction = direction.normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# الجاذبية
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	move_and_slide()


# =========================
# CASHIER MODE
# =========================

func enter_cashier_mode(stand_point: Marker3D):

	if stand_point == null:
		return

	global_position = stand_point.global_position
	global_rotation.y = stand_point.global_rotation.y

	velocity = Vector3.ZERO
	in_cashier_mode = true

	print("PLAYER MOVED TO CASHIER")
	print("CASHIER MODE: ON")


func exit_cashier_mode():

	in_cashier_mode = false

	print("CASHIER MODE: OFF")


# =========================
# COMPUTER MODE
# =========================

func enter_computer_mode():

	if in_cashier_mode:
		return

	in_computer_mode = true
	velocity = Vector3.ZERO

	print("COMPUTER MODE: ON")


func exit_computer_mode():

	in_computer_mode = false

	print("COMPUTER MODE: OFF")


# =========================
# PRODUCT PICKUP
# =========================

func can_pickup_product(product: Node) -> bool:

	if in_cashier_mode or in_computer_mode:
		return false

	if not is_instance_valid(product):
		return false

	if product.get_meta("checkout_locked", false):
		print("PRODUCT LOCKED: Checkout")
		return false

	return true


# =========================
# BARCODE SCANNER
# =========================

func scan_checkout_product(product: Node3D) -> void:

	if barcode_scanner == null:
		push_error("BarcodeScanner not found!")
		return

	barcode_scanner.scan_product(product)
