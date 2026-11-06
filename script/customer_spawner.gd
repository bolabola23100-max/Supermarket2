extends Node

@export var customer_scene: PackedScene     # اسحب customer.tscn هنا
@export var interval_min: float = 15.0
@export var interval_max: float = 30.0
@export var max_customers: int = 3
@export var is_open: bool = true            # المتجر مفتوح؟

var _alive: int = 0


func _ready():
	_loop()


func _loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(interval_min, interval_max)).timeout
		if not is_inside_tree():
			return
		if not is_open or _alive >= max_customers:
			continue
		if not _shelves_have_products():
			continue
		_spawn()


func _shelves_have_products() -> bool:
	for z in get_tree().get_nodes_in_group("product_points"):
		if "products" in z and not z.products.is_empty():
			return true
	return false


func _spawn() -> void:
	if customer_scene == null:
		print("CUSTOMER SCENE NOT SET")
		return
	var c = customer_scene.instantiate()
	get_tree().current_scene.add_child(c)
	_alive += 1
	c.tree_exited.connect(_on_customer_gone)


func _on_customer_gone() -> void:
	_alive = maxi(0, _alive - 1)
