extends Node

signal prices_changed

var products: Dictionary = {
	"Milk": {
		"scene": "res://products/milk.tscn",
		"buy": 10.0,
		"market": 15.0,
		"pack": 12,
		"shelf_limit": 12
	},
	"bread": {
		"scene": "res://products/bread.tscn",
		"buy": 4.5,
		"market": 6.0,
		"pack": 12,
		"shelf_limit": 12
	}
}

var sell_prices: Dictionary = {}


func _ready():
	for n in products:
		sell_prices[n] = products[n]["market"]


# أسماء المنتجات
func names() -> Array:
	return products.keys()


# الحصول على مشهد المنتج
func get_scene(n: String) -> PackedScene:
	if not products.has(n):
		return null

	return load(products[n]["scene"]) as PackedScene


# عدد المنتجات داخل الكرتونة
func get_pack_size(n: String) -> int:
	if not products.has(n):
		return 0

	return int(products[n]["pack"])


# سعر شراء المنتج
func get_buy_price(n: String) -> float:
	if not products.has(n):
		return 0.0

	return float(products[n]["buy"])


# سعر السوق
func get_market_price(n: String) -> float:
	if not products.has(n):
		return 0.0

	return float(products[n]["market"])


# تكلفة شراء كرتونة كاملة
func get_pack_cost(n: String) -> float:
	return get_buy_price(n) * get_pack_size(n)


# سعر بيع المنتج
func get_sell_price(n: String, fallback: float = 10.0) -> float:
	return float(sell_prices.get(n, fallback))


# تغيير سعر البيع
func set_sell_price(n: String, value: float) -> void:
	if not products.has(n):
		return

	sell_prices[n] = maxf(0.0, value)
	prices_changed.emit()


# تحديد الحد الأقصى لعرض المنتج على الرفوف
func get_shelf_limit(product_name: String) -> int:
	if not products.has(product_name):
		return 0

	return int(products[product_name].get("shelf_limit", 0))


# حساب احتمالية شراء الزبون
func buy_chance(n: String) -> float:
	if not products.has(n):
		return 1.0

	var ratio := get_sell_price(n) / maxf(get_market_price(n), 0.01)

	if ratio <= 1.0:
		return 1.0

	return clampf(1.0 - (ratio - 1.0) / 0.5, 0.0, 1.0)


# حساب المنتجات الموجودة في المحل
func count_in_store(n: String) -> Dictionary:

	var on_shelves := 0

	for z in get_tree().get_nodes_in_group("product_points"):

		if not ("products" in z):
			continue

		for p in z.products:

			if is_instance_valid(p) and str(p.get("product_name")) == n:
				on_shelves += 1

	var in_cartons := 0

	for c in get_tree().get_nodes_in_group("products"):

		if c.has_method("take_one") and str(c.get("product_name")) == n:
			in_cartons += int(c.get("count"))

	return {
		"shelves": on_shelves,
		"cartons": in_cartons
	}


# بيانات الحفظ
func get_save_data() -> Dictionary:
	return {
		"sell_prices": sell_prices.duplicate()
	}


# تحميل بيانات الحفظ
func load_save_data(data: Dictionary) -> void:

	var saved: Dictionary = data.get("sell_prices", {})

	for n in saved:

		if products.has(n):
			sell_prices[n] = float(saved[n])

	prices_changed.emit()
