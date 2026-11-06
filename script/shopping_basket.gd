extends Node

var products: Array = []

func add_product(product_name: String):
	if not ProductDB.products.has(product_name):
		return

	var product_price: float = ProductDB.get_sell_price(product_name)

	var product = {
		"name": product_name,
		"price": product_price
	}

	products.append(product)

	print("Product added: ", product_name)
	print("Selling price: ", product_price)


func get_product_count() -> int:
	return products.size()


func get_total_price() -> float:
	var total: float = 0.0

	for product in products:
		total += float(product["price"])

	return total


func clear_basket():
	products.clear()
