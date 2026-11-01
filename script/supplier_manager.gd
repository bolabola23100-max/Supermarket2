extends Node

@export var delivery_time: float = 10.0

var wholesale_prices = {
	"Milk": 15.0,
	"Bread": 7.0,
	"Juice": 10.0
}

var inventory_manager
var money_manager

func _ready():
	inventory_manager = get_node("../InventoryManager")
	money_manager = get_node("../MoneyManager")
func order_product(product_name: String, quantity: int):

	if not wholesale_prices.has(product_name):
		print("PRODUCT NOT FOUND!")
		return

	if quantity <= 0:
		print("INVALID QUANTITY!")
		return

	var total_cost = wholesale_prices[product_name] * quantity

	print("======================")
	print("NEW SUPPLIER ORDER")
	print("PRODUCT: ", product_name)
	print("QUANTITY: ", quantity)
	print("TOTAL COST: ", total_cost)
	print("======================")

	if not money_manager.spend_money(total_cost):
		print("ORDER CANCELLED!")
		return

	print("ORDER CONFIRMED!")
	print("WAITING FOR DELIVERY...")

	await get_tree().create_timer(delivery_time).timeout

	inventory_manager.add_stock(product_name, quantity)

	print("======================")
	print("DELIVERY ARRIVED!")
	print("PRODUCT: ", product_name)
	print("QUANTITY: ", quantity)
	print("======================")
func order_product_without_payment(product_name: String, quantity: int):
	if not wholesale_prices.has(product_name):
		return

	if quantity <= 0:
		return

	print("SUPPLIER ORDER: ", product_name)

	await get_tree().create_timer(delivery_time).timeout

	inventory_manager.add_stock(product_name, quantity)

	print("DELIVERY ARRIVED!")
