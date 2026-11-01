extends Node

@export var hold_distance: float = 1.5
@export var put_distance: float = 3.0

var held_product: Node3D = null
var held_original_parent: Node = null
var held_original_position: Vector3
var held_original_rotation: Vector3

var player
var camera
var interaction_ray


func _ready():

	player = get_parent()

	camera = player.get_node("Camera3D")
	interaction_ray = camera.get_node("InteractionRay")


func _process(_delta):

	if held_product != null:
		update_held_product()


func interact():

	if held_product == null:
		try_pickup()

	else:
		try_put_down()


# =========================
# PICK UP
# =========================

func try_pickup():

	print("TRY PICKUP")

	print("RAY ENABLED: ", interaction_ray.enabled)
	print("RAY COLLIDING: ", interaction_ray.is_colliding())

	if not interaction_ray.is_colliding():
		print("RAY NOT COLLIDING")
		return

	var object = interaction_ray.get_collider()

	print("HIT OBJECT: ", object)

	if object == null:
		return

	var product = find_product(object)

	if product == null:
		print("NOT A PRODUCT")
		return

	pickup_product(product)

func find_product(object):

	var current = object

	while current != null:

		if current.is_in_group("products"):
			return current

		current = current.get_parent()

	return null

func pickup_product(product):

	held_product = product

	held_original_parent = product.get_parent()
	held_original_position = product.global_position
	held_original_rotation = product.global_rotation

	product.freeze = true
	interaction_ray.add_exception(product)
	product.get_parent().remove_child(product)

	camera.add_child(product)

	product.position = Vector3(0, 0, -hold_distance)
	product.rotation = Vector3.ZERO

	print("PRODUCT PICKED UP")

# =========================
# HOLD PRODUCT
# =========================

func update_held_product():

	if held_product == null:
		return

	held_product.position = Vector3(0, 0, -hold_distance)


# =========================
# PUT DOWN
# =========================

func try_put_down():

	if not interaction_ray.is_colliding():
		return

	var object = interaction_ray.get_collider()
	print("PUT HIT: ", object)
	if object == null:
		return

	var product_point = find_product_point(object)

	if product_point == null:
		return

	var distance = camera.global_position.distance_to(
		product_point.global_position
	)

	if distance > put_distance:
		print("TOO FAR FROM SHELF")
		return

	put_product(product_point)


func find_product_point(object):

	if object is Area3D:

		if object.is_in_group("product_points"):
			return object

	if object is CollisionObject3D:

		var parent = object.get_parent()

		if parent != null:

			if parent.is_in_group("product_points"):
				return parent

	return null


func put_product(product_point):

	var product = held_product

	camera.remove_child(product)

	product_point.add_child(product)

	product.global_position = product_point.global_position
	product.global_rotation = product_point.global_rotation

	product.freeze = true

	interaction_ray.remove_exception(product)

	held_product = null
	held_original_parent = null

	print("PRODUCT PLACED ON SHELF")
