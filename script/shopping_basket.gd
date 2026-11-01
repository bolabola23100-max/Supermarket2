extends Node

var products: Array = []

var product_prices = {
	"Milk": 30.0,
	"Bread": 15.0,
	"Juice": 20.0
}

func add_product(product_name: String):
	if not product_prices.has(product_name):
		return

	var product = {
		"name": product_name,
		"price": product_prices[product_name]
	}

	products.append(product)

	print("Product added: ", product_name)
	print("Price: ", product["price"])

func get_product_count() -> int:
	return products.size()

func get_total_price() -> float:
	var total = 0.0

	for product in products:
		total += product["price"]

	return total

func clear_basket():
	products.clear()
