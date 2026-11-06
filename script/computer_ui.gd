extends Control

# =========================
# MAIN PAGES
# =========================

@onready var main_menu = $Background/Sprite2D
@onready var order_page = $OrderPage
@onready var stock_page = $StockPage

@onready var order_button = $Background/Sprite2D/OrderButton
@onready var stock_button = $Background/Sprite2D/StockButton

@onready var stock_back_button = $StockPage/VBoxContainer/StockBackButton


# =========================
# SUPPLIER UI
# =========================

var supplier_ui: Control = null


# =========================
# STOCK UI
# =========================

@onready var product_option: OptionButton = $StockPage/VBoxContainer/ProductOption
@onready var current_price_label: Label = $StockPage/VBoxContainer/CurrentPriceLabel
@onready var market_price_label: Label = $StockPage/VBoxContainer/MarketPriceLabel
@onready var stock_amount_label: Label = $StockPage/VBoxContainer/StockAmountLabel
@onready var new_price_input: SpinBox = $StockPage/VBoxContainer/NewPriceInput
@onready var update_price_button: Button = $StockPage/VBoxContainer/UpdatePriceButton

var inventory_manager: Node = null


# =========================
# READY
# =========================

func _ready():

	# العثور على واجهة المورد
	supplier_ui = find_child("SupplierUI", true, false) as Control

	# العثور على InventoryManager
	inventory_manager = get_node_or_null("/root/Supermarket/InventoryManager")

	if inventory_manager == null:
		inventory_manager = get_tree().current_scene.find_child(
			"InventoryManager", true, false
		)

	# إعداد الصفحات
	order_page.hide()
	stock_page.hide()
	main_menu.show()

	if supplier_ui != null:
		supplier_ui.hide()

		# ربط زر X بالعودة للقائمة الرئيسية
		if supplier_ui.has_signal("supplier_closed"):
			supplier_ui.supplier_closed.connect(back_to_main)
	else:
		push_error("SupplierUI not found!")

	# ربط أزرار القائمة
	order_button.pressed.connect(open_order_page)
	stock_button.pressed.connect(open_stock_page)

	stock_back_button.pressed.connect(back_to_main)

	# إعداد صفحة المخزون
	product_option.item_selected.connect(update_stock_info)
	new_price_input.value_changed.connect(update_new_price_preview)
	update_price_button.pressed.connect(apply_new_price)

	# إضافة المنتجات
	load_products()

	if product_option.item_count > 0:
		update_stock_info(0)


# =========================
# MAIN MENU
# =========================

func open_order_page():

	main_menu.hide()
	stock_page.hide()

	order_page.show()

	if supplier_ui != null:
		supplier_ui.show()


func open_stock_page():

	main_menu.hide()
	order_page.hide()

	if supplier_ui != null:
		supplier_ui.hide()

	stock_page.show()

	if product_option.item_count > 0:
		update_stock_info(product_option.selected)


func back_to_main():
	print("========== BACK TO MAIN ==========")

	order_page.hide()
	stock_page.hide()

	if supplier_ui != null:
		supplier_ui.hide()

	main_menu.show()

	print("MAIN MENU VISIBLE: ", main_menu.visible)

# =========================
# LOAD PRODUCTS
# =========================

func load_products():

	product_option.clear()

	for product_name in ProductDB.names():
		product_option.add_item(product_name)


# =========================
# UPDATE STOCK INFO
# =========================

func update_stock_info(_index: int = 0):

	if product_option.item_count == 0:
		return

	var product_name = product_option.get_item_text(
		product_option.selected
	)

	var current_price = ProductDB.get_sell_price(product_name)
	var market_price = ProductDB.get_market_price(product_name)

	current_price_label.text = "سعر البيع الحالي: %.2f" % current_price
	market_price_label.text = "سعر السوق: %.2f" % market_price

	new_price_input.value = current_price

	# المخزون المسجل في InventoryManager
	var manager_stock := 0

	if inventory_manager != null:
		manager_stock = inventory_manager.get_stock(product_name)

	# المخزون الفعلي في المتجر
	var physical_stock: Dictionary = ProductDB.count_in_store(product_name)

	var shelves := int(physical_stock.get("shelves", 0))
	var cartons := int(physical_stock.get("cartons", 0))

	stock_amount_label.text = (
		"المخزون المسجل: %d قطعة\n" +
		"على الرفوف: %d قطعة\n" +
		"داخل الكراتين: %d قطعة\n" +
		"الإجمالي الفعلي: %d قطعة"
	) % [
		manager_stock,
		shelves,
		cartons,
		shelves + cartons
	]


# =========================
# PRICE PREVIEW
# =========================

func update_new_price_preview(_value: float):

	if product_option.item_count == 0:
		return

	var new_price = new_price_input.value

	current_price_label.text = "السعر الجديد: %.2f" % new_price


# =========================
# APPLY NEW PRICE
# =========================

func apply_new_price():

	if product_option.item_count == 0:
		return

	var product_name = product_option.get_item_text(
		product_option.selected
	)

	var new_price = new_price_input.value

	if new_price < 0.0:
		return

	ProductDB.set_sell_price(product_name, new_price)

	update_stock_info(product_option.selected)

	print("======================")
	print("PRICE UPDATED")
	print("PRODUCT: ", product_name)
	print("NEW PRICE: ", new_price)
	print("======================")
