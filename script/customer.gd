extends CharacterBody3D

const TYPES := {
	"normal": {"speed": 2.0, "items_min": 1, "items_max": 3, "pick_time": 2.5, "patience": 60.0, "budget": 60.0, "weight": 50},
	"rushed": {"speed": 3.2, "items_min": 1, "items_max": 2, "pick_time": 1.2, "patience": 25.0, "budget": 40.0, "weight": 20},
	"big": {"speed": 1.7, "items_min": 4, "items_max": 7, "pick_time": 3.0, "patience": 90.0, "budget": 200.0, "weight": 15},
	"cheap": {"speed": 2.0, "items_min": 1, "items_max": 4, "pick_time": 2.0, "patience": 45.0, "budget": 20.0, "weight": 15},
}

@export var customer_type: String = ""
@export var stand_distance: float = 0.8
@export var walk_timeout: float = 30.0
@export var basket_offset: Vector3 = Vector3(0.3, 0.9, -0.35)

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var shopping_basket = $ShoppingBasket
@onready var hand_point: Marker3D = $HandPoint

signal arrived

var move_speed: float = 2.0
var items_min: int = 1
var items_max: int = 3
var pick_time: float = 2.5
var patience: float = 60.0
var budget: float = 60.0

var _moving := false
var _walk_time := 0.0
var _spawn_pos := Vector3.ZERO

var basket: Array = []
var _carried: Array = []

var _checkout_done := false
var paid_total := 0.0


func _ready():
	collision_layer = 16
	collision_mask = 4

	_apply_type()

	var spawn = get_node_or_null("../CustomerSpawnPoint")
	if spawn:
		global_position = spawn.global_position

	_spawn_pos = global_position

	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5

	_run()


# =========================
# CUSTOMER TYPE
# =========================

func _apply_type() -> void:
	if not TYPES.has(customer_type):
		customer_type = _random_type()

	var t: Dictionary = TYPES[customer_type]

	move_speed = t["speed"]
	items_min = t["items_min"]
	items_max = t["items_max"]
	pick_time = t["pick_time"]
	patience = t["patience"]
	budget = t["budget"]

	print("NEW CUSTOMER: ", customer_type)


func _random_type() -> String:
	var total := 0

	for k in TYPES:
		total += int(TYPES[k]["weight"])

	var r := randi_range(1, total)

	for k in TYPES:
		r -= int(TYPES[k]["weight"])

		if r <= 0:
			return str(k)

	return "normal"


# =========================
# CUSTOMER SHOPPING ROUTINE
# =========================

func _run() -> void:
	await get_tree().create_timer(1.0).timeout

	var wanted := randi_range(items_min, items_max)
	var spent := 0.0

	for i in wanted:
		var zone = _pick_zone(budget - spent)

		if zone == null:
			break

		await _walk_to(zone.get_stand_position(stand_distance))

		var got: float = await _pick_from(zone)
		spent += got

	if basket.is_empty():
		print("CUSTOMER (", customer_type, ") LEFT EMPTY-HANDED")
	else:
		await _checkout()

	await _leave()


# =========================
# PRODUCT SELECTION
# =========================

func _pick_zone(remaining: float):
	var zones: Array = []

	for z in get_tree().get_nodes_in_group("product_points"):
		if not z.has_method("peek_product"):
			continue

		var p = z.peek_product()

		if p == null:
			continue

		var pname := str(_read(p, "product_name", ""))

		if ProductDB.get_sell_price(pname, 10.0) > remaining:
			continue

		if randf() > ProductDB.buy_chance(pname):
			continue

		zones.append(z)

	if zones.is_empty():
		return null

	return zones.pick_random()


func _pick_from(zone) -> float:
	var d: Vector3 = zone.global_position - global_position
	d.y = 0.0

	if d.length() > 0.01:
		rotation.y = atan2(-d.x, -d.z)

	await get_tree().create_timer(pick_time).timeout

	var p = zone.take_product()

	if p == null:
		print("SHELF EMPTY")
		return 0.0

	var item_name: String = str(_read(p, "product_name", "Product"))

	var item_price: float = ProductDB.get_sell_price(
		item_name,
		float(_read(p, "price", 10.0))
	)

	basket.append({
		"name": item_name,
		"price": item_price
	})

	shopping_basket.add_product(item_name)

	_attach_to_basket(p)

	print("CUSTOMER TOOK: ", item_name, " - ", item_price)

	return item_price


func _read(node, prop: String, fallback):
	var v = node.get(prop)
	return fallback if v == null else v


# =========================
# CARRY PRODUCTS
# =========================

func _attach_to_basket(p) -> void:
	if not is_instance_valid(p):
		return

	p.collision_layer = 0
	p.collision_mask = 0

	if p is RigidBody3D:
		p.freeze = true
		p.linear_velocity = Vector3.ZERO
		p.angular_velocity = Vector3.ZERO

	p.reparent(self, true)

	if not _carried.has(p):
		_carried.append(p)

	var target_position: Vector3

	if is_instance_valid(hand_point):
		target_position = hand_point.position
	else:
		target_position = basket_offset

	var offset := Vector3(
		0.0,
		0.05 * (_carried.size() - 1),
		0.0
	)

	var tw := create_tween().set_parallel(true)

	tw.tween_property(
		p,
		"position",
		target_position + offset,
		0.4
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tw.tween_property(
		p,
		"quaternion",
		Quaternion.IDENTITY,
		0.4
	)


# =========================
# CHECKOUT AND QUEUE
# =========================

func _checkout() -> void:
	var cm = get_node_or_null("../CheckoutManager")

	if cm == null:
		_auto_pay()
		return

	cm.join(self)

	var joined := Time.get_ticks_msec()
	var last_idx := -2
	var presented := false

	while not _checkout_done:
		if (Time.get_ticks_msec() - joined) / 1000.0 > patience:
			print("CUSTOMER (", customer_type, ") LOST PATIENCE")
			cm.abort(self)
			return

		var idx: int = cm.index_of(self)

		if idx < 0:
			return

		if idx != last_idx:
			last_idx = idx
			await _walk_to(cm.slot_position(idx))
			continue

		if idx == 0 and not presented:
			presented = true

			_face(cm.counter_position())

			var items := _carried.duplicate()
			_carried.clear()

			cm.present_items(self, items)

		await get_tree().create_timer(0.3).timeout


# =========================
# RECEIVE PURCHASED ITEMS
# =========================

func receive_purchased_items(products: Array) -> void:
	for p in products:
		if not is_instance_valid(p):
			continue

		p.set_meta("checkout_locked", true)
		p.set_meta("scanned", true)

		if p is RigidBody3D:
			p.freeze = true
			p.linear_velocity = Vector3.ZERO
			p.angular_velocity = Vector3.ZERO

		_attach_to_basket(p)

	print("CUSTOMER RECEIVED ", products.size(), " PURCHASED ITEMS")


func checkout_finished(total: float) -> void:
	paid_total = total
	_checkout_done = true

	print("CUSTOMER PAID: ", paid_total)


# =========================
# AUTOMATIC PAYMENT
# =========================

func _auto_pay() -> void:
	var total: float = shopping_basket.get_total_price()

	var money_manager = get_node_or_null("../MoneyManager")

	if money_manager:
		money_manager.add_money(total)

	paid_total = total

	print("AUTO PAY: ", total)

# =========================
# FACE TARGET
# =========================

func _face(pos: Vector3) -> void:
	var d := pos - global_position
	d.y = 0.0

	if d.length() > 0.01:
		rotation.y = atan2(-d.x, -d.z)


# =========================
# LEAVE STORE
# =========================

func _drop_items() -> void:
	for c in _carried:
		if is_instance_valid(c):
			c.queue_free()

	_carried.clear()
	basket.clear()

	if is_instance_valid(shopping_basket):
		shopping_basket.clear_basket()


func _leave() -> void:
	_drop_items()

	var exit_node = get_node_or_null("../ExitPoint")

	await _walk_to(
		exit_node.global_position if exit_node else _spawn_pos
	)

	queue_free()


# =========================
# MOVEMENT
# =========================

func _walk_to(pos: Vector3) -> void:
	var nav_map := navigation_agent.get_navigation_map()

	navigation_agent.target_position = NavigationServer3D.map_get_closest_point(
		nav_map,
		pos
	)

	await get_tree().physics_frame

	_walk_time = 0.0
	_moving = true

	await arrived


func _finish_move() -> void:
	_moving = false
	velocity = Vector3.ZERO
	arrived.emit()


func _physics_process(delta):
	if not _moving:
		return

	if navigation_agent.is_navigation_finished():
		_finish_move()
		return

	_walk_time += delta

	if _walk_time > walk_timeout:
		print("CUSTOMER STUCK - SKIPPING")
		_finish_move()
		return

	var next_position := navigation_agent.get_next_path_position()

	var dir := global_position.direction_to(next_position)
	dir.y = 0.0

	if dir.length() > 0.01:
		dir = dir.normalized()

		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		velocity.y = 0.0

		rotation.y = lerp_angle(
			rotation.y,
			atan2(-dir.x, -dir.z),
			8.0 * delta
		)

		move_and_slide()
