extends Node

var inventory = {
	"Milk": 10,
	"Bread": 15,
	"Juice": 8
}


func has_stock(product_name: String) -> bool:
	return inventory.get(product_name, 0) > 0


func take_product(product_name: String) -> bool:
	if not has_stock(product_name):
		return false

	inventory[product_name] -= 1

	print("PRODUCT SOLD: ", product_name)
	print("REMAINING STOCK: ", inventory[product_name])

	return true


func add_stock(product_name: String, quantity: int):
	if quantity <= 0:
		return

	if not inventory.has(product_name):
		return

	inventory[product_name] += quantity

	print("======================")
	print("STOCK RESTOCKED: ", product_name)
	print("ADDED QUANTITY: ", quantity)
	print("TOTAL STOCK: ", inventory[product_name])
	print("======================")


func get_random_available_product() -> String:
	var available_products: Array = []

	for product_name in inventory:
		if inventory[product_name] > 0:
			available_products.append(product_name)

	if available_products.is_empty():
		return ""

	return available_products.pick_random()


func get_stock(product_name: String) -> int:
	return inventory.get(product_name, 0)
