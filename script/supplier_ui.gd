extends Control

signal supplier_closed

@export var product_card_scene: PackedScene

@onready var products_grid: GridContainer = $ProductsScroll/ProductsGrid
@onready var close_button: Button = $Header/HBoxContainer/CloseButton

@onready var cart_count_label: Label = $Footer/HBoxContainer/CartCountLabel
@onready var total_label: Label = $Footer/HBoxContainer/TotalLabel
@onready var place_order_button: Button = $Footer/HBoxContainer/PlaceOrderButton

var supplier_manager: Node
var cart: Dictionary = {}


func _ready():
	supplier_manager = get_node("/root/Supermarket/SupplierManager")

	close_button.pressed.connect(close_supplier)
	place_order_button.pressed.connect(place_order)

	load_products()
	update_cart()
	hide()


# =========================
# LOAD PRODUCTS
# =========================

func load_products():
	for child in products_grid.get_children():
		child.queue_free()

	if product_card_scene == null:
		push_error("Product Card Scene is not assigned!")
		return

	for product_name in ProductDB.names():
		var card = product_card_scene.instantiate()
		products_grid.add_child(card)

		var stock: Dictionary = ProductDB.count_in_store(product_name)
		var pack_size: int = ProductDB.get_pack_size(product_name)
		var pack_price: float = ProductDB.get_pack_cost(product_name)

		card.setup(
			product_name,
			stock,
			pack_size,
			pack_price
		)

		card.add_to_cart.connect(_on_add_to_cart)


# =========================
# CART
# =========================

func _on_add_to_cart(product_name: String, packs: int):
	cart[product_name] = int(cart.get(product_name, 0)) + packs
	update_cart()


func update_cart():
	var total_items := 0
	var total_cost := 0.0

	for product_name in cart:
		var packs: int = int(cart[product_name])

		total_items += packs
		total_cost += ProductDB.get_pack_cost(product_name) * packs

	cart_count_label.text = "Cart: %d Cartons" % total_items
	total_label.text = "Total: %.2f" % total_cost

	place_order_button.disabled = cart.is_empty()


# =========================
# PLACE ORDER
# =========================

func place_order():
	if cart.is_empty():
		return

	var messages: Array[String] = []

	for product_name in cart.keys():
		var packs: int = int(cart[product_name])

		var result: String = supplier_manager.place_order(
			product_name,
			packs
		)

		messages.append(product_name + ": " + result)

	print("\n".join(messages))

	cart.clear()
	update_cart()


# =========================
# CLOSE SUPPLIER
# =========================

func close_supplier():
	print("========== X PRESSED ==========")
	print("Supplier UI: ", visible)

	supplier_closed.emit()

	print("CLOSE SIGNAL SENT")
	hide()
