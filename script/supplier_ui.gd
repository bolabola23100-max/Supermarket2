extends Control

@onready var product_option = $Panel/VBoxContainer/ProductOption
@onready var quantity_input = $Panel/VBoxContainer/QuantityInput

@onready var price_label = $Panel/VBoxContainer/PriceLabel
@onready var order_button = $Panel/VBoxContainer/OrderButton
@onready var result_label = $Panel/VBoxContainer/ResultLabel
@onready var close_button = $Panel/VBoxContainer/CloseButton

var supplier_manager

var product_prices = {
	"Milk": 15.0,
	"Bread": 7.0,
	"Juice": 10.0
}


func _ready():
	supplier_manager = get_node("/root/Supermarket/SupplierManager")

	product_option.add_item("Milk")
	product_option.add_item("Bread")
	product_option.add_item("Juice")

	product_option.item_selected.connect(update_price)
	quantity_input.value_changed.connect(update_price)

	order_button.pressed.connect(make_order)
	close_button.pressed.connect(close_supplier)

	update_price()
	hide()


func update_price(_value = 0):
	var product = product_option.get_item_text(product_option.selected)
	var quantity = int(quantity_input.value)

	var total = product_prices[product] * quantity

	price_label.text = "Total Cost: " + str(total)


func make_order():
	var product = product_option.get_item_text(product_option.selected)
	var quantity = int(quantity_input.value)

	var total = product_prices[product] * quantity

	if not supplier_manager.money_manager.spend_money(total):
		result_label.text = "Not enough money!"
		return

	supplier_manager.order_product_without_payment(product, quantity)

	result_label.text = "Order placed successfully!"


func close_supplier():
	hide()
