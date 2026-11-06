extends Node

signal order_placed(product_name, packs)
signal order_delivered(product_name, packs)

@export var carton_scene: PackedScene        # اسحب carton.tscn هنا
@export var delivery_delay: float = 5.0      # ثواني لحد ما الطلب يوصل
@export var columns: int = 3                 # عدد الكراتين في الصف

var money_manager
var pending: Array = []      # الطلبات اللي لسه ما وصلتش [{id, product, packs}]
var _next_id: int = 1


func _ready():
	money_manager = get_node_or_null("../MoneyManager")


# بيرجع نص يتعرض في الواجهة
func place_order(product_name: String, packs: int) -> String:
	if not ProductDB.products.has(product_name) or packs <= 0:
		return "Invalid order!"
	if carton_scene == null:
		return "Carton scene not set!"

	var total := ProductDB.get_pack_cost(product_name) * packs
	if money_manager == null or not money_manager.spend_money(total):
		return "Not enough money!"

	var order := {"id": _next_id, "product": product_name, "packs": packs}
	_next_id += 1
	pending.append(order)

	order_placed.emit(product_name, packs)
	_deliver(order, delivery_delay)
	return "Order placed! Arrives in %d s" % int(delivery_delay)


func _deliver(order: Dictionary, delay: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	_spawn_cartons(str(order["product"]), int(order["packs"]))
	_remove_pending(int(order["id"]))
	order_delivered.emit(order["product"], order["packs"])


func _remove_pending(id: int) -> void:
	for i in pending.size():
		if int(pending[i]["id"]) == id:
			pending.remove_at(i)
			return


@warning_ignore("integer_division")
func _spawn_cartons(product_name: String, packs: int) -> void:
	var point = get_node_or_null("../DeliveryPoint")
	if point == null:
		print("DELIVERY POINT NOT FOUND")
		return

	var scene := ProductDB.get_scene(product_name)
	var pack := ProductDB.get_pack_size(product_name)
	var root := get_tree().current_scene
	var step := Vector3.ZERO

	for i in packs:
		var c = carton_scene.instantiate()
		c.product_scene = scene        # لازم قبل add_child عشان الكرتونة تتشكل صح
		c.count = pack
		c.product_name = product_name
		root.add_child(c)

		if step == Vector3.ZERO:
			var s: Vector3 = c._outer
			step = Vector3(s.x + 0.1, s.y + 0.05, s.z + 0.1)

		var col := i % columns
		var row := (i / columns) % 2
		var layer := i / (columns * 2)
		var basis: Basis = point.global_basis.orthonormalized()
		c.global_basis = basis
		c.global_position = point.global_position \
			+ basis.x * step.x * col \
			+ basis.z * step.z * row \
			+ Vector3(0.0, step.y * (layer + 0.5) + 0.05, 0.0)

	print("DELIVERED: ", packs, " x ", product_name)


# =========================
# الحفظ
# =========================

func get_save_data() -> Dictionary:
	var list: Array = []
	for o in pending:
		list.append({"product": o["product"], "packs": o["packs"]})
	return {"pending": list}


# الطلبات المعلقة توصل فوراً بعد التحميل
func load_save_data(data: Dictionary) -> void:
	for o in data.get("pending", []):
		var order := {
			"id": _next_id,
			"product": str(o.get("product", "")),
			"packs": int(o.get("packs", 1)),
		}
		_next_id += 1
		if not ProductDB.products.has(order["product"]):
			continue
		pending.append(order)
		_deliver(order, 0.0)
