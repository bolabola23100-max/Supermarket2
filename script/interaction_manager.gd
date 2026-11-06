extends Node

@export var carton_hold_rotation: Vector3 = Vector3(25, 0, 0)
@export var hold_distance: float = 1.5
@export var put_distance: float = 3.0
@export var carton_places_all: bool = false
@export var open_on_pickup: bool = false

# حركة الكرتونة مع اللف
@export var sway_strength: float = 1.0
@export var sway_follow_speed: float = 10.0
@export var sway_max_angle: float = 15.0

var held_product: RigidBody3D = null
var held_layer: int = 1
var held_mask: int = 5
var held_scale: Vector3 = Vector3.ONE

var _hold_quat: Quaternion = Quaternion.IDENTITY
var _hand_q: Quaternion = Quaternion.IDENTITY

var player
var camera
var interaction_ray: RayCast3D

var barcode_scanner: Node = null
var exit_cashier_button: Button
var cashier_highlight: MeshInstance3D = null


func _ready():
	player = get_parent()
	camera = player.get_node("Camera3D")
	interaction_ray = camera.get_node("InteractionRay")

	interaction_ray.enabled = true
	interaction_ray.collide_with_bodies = true
	interaction_ray.collide_with_areas = true
	interaction_ray.collision_mask = 0b11

	if player is CollisionObject3D:
		interaction_ray.add_exception(player)

	# Barcode Scanner
	barcode_scanner = get_tree().current_scene.find_child(
		"BarcodeScanner", true, false
	)

	if barcode_scanner == null:
		push_error("BARCODE SCANNER NOT FOUND!")
	else:
		print("BARCODE SCANNER CONNECTED!")

	# Exit Cashier Button
	exit_cashier_button = get_tree().current_scene.find_child(
		"ExitCashierButton", true, false
	)

	if exit_cashier_button == null:
		push_error("EXIT CASHIER BUTTON NOT FOUND!")

	# Cashier Highlight
	cashier_highlight = get_tree().current_scene.find_child(
		"CashierHighlight", true, false
	) as MeshInstance3D

	if cashier_highlight != null:
		cashier_highlight.visible = false
		print("CASHIER HIGHLIGHT CONNECTED!")
	else:
		push_warning("CashierHighlight NOT FOUND!")


func _process(delta):
	update_cashier_highlight()

	if held_product == null:
		return

	var cam_q: Quaternion = camera.global_basis.get_rotation_quaternion()
	var follow: float = 1.0 - exp(-sway_follow_speed * delta)

	_hand_q = _hand_q.slerp(cam_q, follow)

	var diff: Vector3 = (cam_q.inverse() * _hand_q).get_euler()
	var limit: float = deg_to_rad(sway_max_angle)

	var sx: float = clampf(
		diff.x * 0.5 * sway_strength,
		-limit,
		limit
	)

	var sy: float = clampf(
		diff.y * sway_strength,
		-limit,
		limit
	)

	var sway_q: Quaternion = Quaternion.from_euler(
		Vector3(sx, sy, 0.0)
	)

	held_product.position = sway_q * Vector3(
		0.0,
		0.0,
		-hold_distance
	)

	held_product.quaternion = sway_q * _hold_quat


# =========================
# CASHIER HIGHLIGHT
# =========================

func update_cashier_highlight():
	if cashier_highlight == null:
		return

	if player.in_cashier_mode or player.in_computer_mode:
		cashier_highlight.visible = false
		return

	interaction_ray.force_raycast_update()

	if not interaction_ray.is_colliding():
		cashier_highlight.visible = false
		return

	var highlight_target = interaction_ray.get_collider()
	var highlight_cashier = find_cashier(highlight_target)

	cashier_highlight.visible = highlight_cashier != null


# =========================
# INTERACTION
# =========================

func interact():

	# الخروج من وضع الكمبيوتر
	if player.in_computer_mode:
		player.exit_computer_mode()
		print("EXITED COMPUTER")
		return

	# وضع الكاشير
	if player.in_cashier_mode:

		if held_product != null:
			return

		interaction_ray.force_raycast_update()

		if not interaction_ray.is_colliding():
			return

		var cashier_object = interaction_ray.get_collider()

		if cashier_object == null:
			return

		var cashier_product = find_product(cashier_object)

		if cashier_product == null:
			return

		if cashier_product.get_meta("scan_owner", null) == null:
			return

		if cashier_product.get_meta("scanned", false):
			print("PRODUCT ALREADY SCANNED")
			return

		if barcode_scanner == null:
			print("BARCODE SCANNER NOT FOUND!")
			return

		print("MANUAL SCAN REQUEST: ", cashier_product.name)
		barcode_scanner.scan_product(cashier_product)
		return

	# وضع المنتج في الرف
	if held_product != null:
		try_put_down()
		return

	interaction_ray.force_raycast_update()

	if not interaction_ray.is_colliding():
		return

	var object = interaction_ray.get_collider()

	if object == null:
		return

	print("INTERACT HIT: ", object)

	# البحث عن منتج
	var product = find_product(object)

	if product != null:

		if product.get_meta("scan_owner", null) != null:
			print("ENTER CASHIER MODE TO SCAN!")
			return

		if product.get_meta("checkout_locked", false):
			print("PRODUCT LOCKED: CHECKOUT")
			return

		if product.get_meta("scanned", false):
			print("PRODUCT ALREADY SCANNED")
			return

		pickup_product(product)
		return

	# البحث عن الكمبيوتر
	var computer = find_computer(object)

	if computer != null:
		if held_product != null:
			return

		player.enter_computer_mode()
		print("COMPUTER MODE ACTIVATED")
		return

	# البحث عن الكاشير
	var cashier = find_cashier(object)

	if cashier != null:

		var stand_point = cashier.find_child(
			"CashierStandPoint", true, false
		) as Marker3D

		if stand_point == null:
			push_error("CashierStandPoint NOT FOUND!")
			return

		player.enter_cashier_mode(stand_point)

		if exit_cashier_button != null:
			exit_cashier_button.visible = true

		return

	print("NOT A PRODUCT, CASHIER OR COMPUTER")


# =========================
# FIND PRODUCT
# =========================

func find_product(object):
	var current = object

	while current != null:
		if current.is_in_group("products"):
			return current

		current = current.get_parent()

	return null


# =========================
# FIND CASHIER
# =========================

func find_cashier(object):
	var current = object

	while current != null:
		if current.is_in_group("cashier"):
			return current

		current = current.get_parent()

	return null


# =========================
# FIND COMPUTER
# =========================

func find_computer(object):
	var current = object

	while current != null:
		if current.is_in_group("computer"):
			return current

		current = current.get_parent()

	return null


# =========================
# PICK UP
# =========================

func try_pickup():
	if player.in_cashier_mode or player.in_computer_mode:
		return

	interaction_ray.force_raycast_update()

	if not interaction_ray.is_colliding():
		return

	var object = interaction_ray.get_collider()

	if object == null:
		return

	var product = find_product(object)

	if product == null:
		return

	if product.get_meta("checkout_locked", false):
		return

	if product.get_meta("scanned", false):
		return

	pickup_product(product)


func pickup_product(product: RigidBody3D):
	held_product = product

	held_layer = product.collision_layer
	held_mask = product.collision_mask
	held_scale = product.global_basis.get_scale()

	if product.has_meta("shelf_zone"):
		var zone = product.get_meta("shelf_zone")

		if is_instance_valid(zone):
			zone.remove_product(product)

	product.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	product.freeze = true

	product.linear_velocity = Vector3.ZERO
	product.angular_velocity = Vector3.ZERO

	product.collision_layer = 0
	product.collision_mask = 0

	product.reparent(camera, true)

	product.position = Vector3(0, 0, -hold_distance)
	product.scale = held_scale

	if product.has_method("take_one"):
		_hold_quat = Quaternion.from_euler(
			Vector3(
				deg_to_rad(carton_hold_rotation.x),
				deg_to_rad(carton_hold_rotation.y),
				deg_to_rad(carton_hold_rotation.z)
			)
		)
	else:
		_hold_quat = Quaternion.IDENTITY

	_hand_q = camera.global_basis.get_rotation_quaternion()

	if open_on_pickup and product.has_method("take_one"):
		product.open()

	print("PRODUCT PICKED UP")


# =========================
# PUT DOWN
# =========================

func try_put_down():
	if player.in_cashier_mode or player.in_computer_mode:
		return

	var carton = held_product

	if carton.has_method("take_one") and not carton.is_open:
		carton.open()
		return

	interaction_ray.force_raycast_update()

	if not interaction_ray.is_colliding():
		return

	var object = interaction_ray.get_collider()

	if object == null:
		return

	var zone = find_zone(object)

	if zone == null:
		return

	var dist = camera.global_position.distance_to(
		interaction_ray.get_collision_point()
	)

	if dist > put_distance:
		print("TOO FAR FROM SHELF")
		return

	if carton.has_method("take_one"):
		put_from_carton(zone)
	else:
		put_single(zone)


# =========================
# FIND SHELF ZONE
# =========================

func find_zone(object):
	if object is Area3D and object.is_in_group("product_points"):
		return object

	var product = find_product(object)

	if product != null and product.has_meta("shelf_zone"):
		return product.get_meta("shelf_zone")

	return null


# =========================
# PUT SINGLE PRODUCT
# =========================

func put_single(zone):
	var product = held_product

	if zone.add_product(product, true):
		product.collision_layer = held_layer
		product.collision_mask = held_mask
		product.freeze = true

		held_product = null

		print("PRODUCT PLACED ON SHELF")


# =========================
# PUT PRODUCTS FROM CARTON
# =========================

func put_from_carton(zone):
	var carton = held_product
	var times: int = carton.count if carton_places_all else 1

	for i in range(times):
		var product = carton.take_one()

		if product == null:
			break

		if not zone.add_product(product, true, i * 0.08):
			carton.give_back(product)
			break

	if carton.count <= 0:
		carton.vanish()
		held_product = null
		print("CARTON EMPTY")
