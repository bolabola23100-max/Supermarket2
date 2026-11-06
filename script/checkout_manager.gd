extends Node
class_name CheckoutManager

@export var queue_spacing: float = 0.8
@export var auto_scan: bool = false
@export var auto_scan_delay: float = 0.7
@export var bagging_spacing: float = 0.25

var customer_queue: Array = []

# المنتجات الموجودة حاليًا على السير
var items_on_conveyor: Array[Node3D] = []

# المنتجات التي لم تدخل السير بعد
var pending_products: Array[Node3D] = []

# المنتجات التي تم مسحها
var scanned_items: Array[Node3D] = []

var current_bill: float = 0.0
var serving_customer: Node3D = null

var checkout_point: Node3D = null
var conveyor_manager: Node = null
var bagging_point: Marker3D = null

var scan_in_progress: bool = false


func _ready() -> void:
	checkout_point = get_node_or_null("../CheckoutPoint") as Node3D

	if checkout_point == null:
		push_error("CheckoutPoint not found!")
		return

	conveyor_manager = get_tree().current_scene.find_child(
		"ConveyorManager", true, false
	)

	var cashier = get_tree().current_scene.find_child(
		"CashierBody", true, false
	)

	if cashier != null:
		bagging_point = cashier.get_node_or_null("BaggingPoint") as Marker3D

	if conveyor_manager == null:
		push_error("ConveyorManager not found!")

	if bagging_point == null:
		push_error("BaggingPoint not found!")
	else:
		print("BaggingPoint found!")


func join(customer: Node3D) -> void:
	if customer != null and not customer_queue.has(customer):
		customer_queue.append(customer)


func index_of(customer: Node3D) -> int:
	return customer_queue.find(customer)


func slot_position(index: int) -> Vector3:
	return checkout_point.global_position + checkout_point.global_basis.z.normalized() * queue_spacing * index


func counter_position() -> Vector3:
	return checkout_point.global_position


# استقبال كل منتجات العميل
func present_items(customer: Node3D, products: Array) -> void:
	if customer == null:
		return

	serving_customer = customer
	current_bill = 0.0
	scan_in_progress = false

	items_on_conveyor.clear()
	pending_products.clear()
	scanned_items.clear()

	if conveyor_manager == null:
		push_error("ConveyorManager missing!")
		return

	# إضافة كل المنتجات لطابور الانتظار
	for product in products:
		if is_instance_valid(product):
			pending_products.append(product)

	print("TOTAL CUSTOMER PRODUCTS: ", pending_products.size())

	# ملء السير حسب الأماكن المتاحة
	_fill_conveyor()

	if pending_products.is_empty() and items_on_conveyor.is_empty():
		_finish_service()
	elif auto_scan:
		_auto_scan_loop()


# إدخال المنتجات المنتظرة إلى السير
func _fill_conveyor() -> void:
	while not pending_products.is_empty():

		if conveyor_manager.get_empty_slots() <= 0:
			break

		var product: Node3D = pending_products[0]

		if not is_instance_valid(product):
			pending_products.pop_front()
			continue

		if conveyor_manager.place_product(product):
			pending_products.pop_front()
			items_on_conveyor.append(product)

			product.set_meta("scan_owner", self)
			product.set_meta("checkout_locked", true)

			product.collision_layer = 1
			product.collision_mask = 0

			if product is RigidBody3D:
				product.freeze = true
				product.linear_velocity = Vector3.ZERO
				product.angular_velocity = Vector3.ZERO

			print("PRODUCT READY FOR SCAN: ", product.name)

		else:
			break

	print("PRODUCTS WAITING: ", pending_products.size())


# مسح المنتج
func scan_item(product: Node3D) -> void:
	if scan_in_progress:
		return

	if not is_instance_valid(product):
		return

	if not items_on_conveyor.has(product):
		return

	scan_in_progress = true

	items_on_conveyor.erase(product)
	scanned_items.append(product)

	var product_name := str(product.get("product_name"))
	var product_price := float(product.get("price"))

	var price := ProductDB.get_sell_price(
		product_name,
		product_price
	)

	print("PRODUCT NAME: ", product_name)
	print("PRODUCT BASE PRICE: ", product_price)
	print("FINAL SCAN PRICE: ", price)

	current_bill += price

	print("SCANNED: ", product_name)
	print("PRICE: ", price)
	print("CURRENT BILL: ", current_bill)

	# تحريك المنتجات المتبقية
	if conveyor_manager != null:
		await conveyor_manager.advance_after_scan(product)

	# نقل المنتج الممسوح للتعبئة
	if is_instance_valid(product):
		_move_to_bagging(product)

	# إدخال منتج جديد من طابور الانتظار
	_fill_conveyor()

	scan_in_progress = false

	# إنهاء الحساب بعد انتهاء كل المنتجات
	if items_on_conveyor.is_empty() and pending_products.is_empty():
		_finish_service()


# نقل المنتج إلى منطقة التعبئة
func _move_to_bagging(product: Node3D) -> void:
	if bagging_point == null:
		push_error("BaggingPoint missing!")
		return

	var index := scanned_items.size() - 1

	var target_position := (
		bagging_point.global_position
		+ bagging_point.global_basis.x * bagging_spacing * index
	)

	if product is RigidBody3D:
		product.freeze = true
		product.linear_velocity = Vector3.ZERO
		product.angular_velocity = Vector3.ZERO

	product.global_position = target_position
	product.set_meta("scanned", true)

	print("PRODUCT MOVED TO BAGGING AREA")


# إنهاء البيع
func _finish_service() -> void:
	var customer := serving_customer

	serving_customer = null

	var total := current_bill
	current_bill = 0.0

	var money_manager = get_node_or_null("../MoneyManager")

	if money_manager != null and total > 0.0:
		money_manager.add_money(total)

	print("CHECKOUT FINISHED: ", total)

	customer_queue.erase(customer)

	var purchased_items: Array = []

	for product in scanned_items:
		if is_instance_valid(product):
			purchased_items.append(product)

	if is_instance_valid(customer):
		if customer.has_method("receive_purchased_items"):
			customer.receive_purchased_items(purchased_items)

		customer.checkout_finished(total)

	scanned_items.clear()
	items_on_conveyor.clear()
	pending_products.clear()

	print("PURCHASED ITEMS DELIVERED TO CUSTOMER: ", purchased_items.size())


# إلغاء خدمة العميل
func abort(customer: Node3D) -> void:
	customer_queue.erase(customer)

	if serving_customer != customer:
		return

	serving_customer = null

	for product in items_on_conveyor:
		if is_instance_valid(product):
			if conveyor_manager != null:
				conveyor_manager.remove_product(product)

			product.queue_free()

	for product in pending_products:
		if is_instance_valid(product):
			product.queue_free()

	items_on_conveyor.clear()
	pending_products.clear()
	scanned_items.clear()

	current_bill = 0.0
	scan_in_progress = false


# المسح التلقائي
func _auto_scan_loop() -> void:
	var customer := serving_customer

	while serving_customer == customer:
		if items_on_conveyor.is_empty():
			if pending_products.is_empty():
				return

			_fill_conveyor()

		if items_on_conveyor.is_empty():
			return

		await get_tree().create_timer(auto_scan_delay).timeout

		if serving_customer != customer:
			return

		if not items_on_conveyor.is_empty():
			await scan_item(items_on_conveyor[0])
