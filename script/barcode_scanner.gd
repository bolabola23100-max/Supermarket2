extends Area3D

@export var scan_delay: float = 0.5

var scanned_products: Array[Node3D] = []
var pending_products: Array[Node3D] = []

var checkout_manager: Node = null
var processing_queue: bool = false


func _ready() -> void:
	monitoring = true
	monitorable = true

	checkout_manager = get_tree().current_scene.find_child(
		"CheckoutManager", true, false
	)

	if checkout_manager == null:
		push_error("CheckoutManager not found!")


func scan_product(product: Node3D) -> void:
	if not is_instance_valid(product):
		return

	if scanned_products.has(product) or pending_products.has(product):
		return

	if not product.is_in_group("products"):
		return

	if checkout_manager == null:
		return

	var scan_owner = product.get_meta("scan_owner", null)

	if scan_owner != checkout_manager:
		print("PRODUCT NOT READY FOR SCAN")
		return

	if not checkout_manager.items_on_conveyor.has(product):
		return

	pending_products.append(product)

	if not processing_queue:
		_process_scan_queue()


# تنفيذ عمليات المسح بالترتيب
func _process_scan_queue() -> void:
	if processing_queue:
		return

	processing_queue = true

	while not pending_products.is_empty():
		var product: Node3D = pending_products.pop_front()

		if not is_instance_valid(product):
			continue

		if not checkout_manager.items_on_conveyor.has(product):
			continue

		scanned_products.append(product)

		print("MANUAL BARCODE SCAN: ", product.name)

		await checkout_manager.scan_item(product)

		await get_tree().create_timer(scan_delay).timeout

		scanned_products.erase(product)

	processing_queue = false
