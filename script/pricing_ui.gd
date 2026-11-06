extends Control

signal add_to_cart(product_name: String, packs: int)

@onready var product_image: TextureRect = $CardBackground/Content/ProductImage
@onready var product_name_label: Label = $CardBackground/Content/ProductName
@onready var stock_label: Label = $CardBackground/Content/StockLabel
@onready var pack_size_label: Label = $CardBackground/Content/PackSizeLabel
@onready var price_label: Label = $CardBackground/Content/PriceLabel

@onready var quantity_label: Label = $CardBackground/Content/QuantityRow/QuantityLabel
@onready var minus_button: Button = $CardBackground/Content/QuantityRow/MinusButton
@onready var plus_button: Button = $CardBackground/Content/QuantityRow/PlusButton
@onready var add_button: Button = $CardBackground/Content/AddToCartButton

var product_name := ""
var quantity := 1


func _ready():
	minus_button.pressed.connect(_on_minus_pressed)
	plus_button.pressed.connect(_on_plus_pressed)
	add_button.pressed.connect(_on_add_pressed)
	update_quantity()


func setup(product: String, stock: Dictionary, size: int, price: float, texture: Texture2D = null):
	product_name = product

	product_name_label.text = product
	stock_label.text = "Shelves: %d | Cartons: %d" % [
		int(stock.get("shelves", 0)),
		int(stock.get("cartons", 0))
	]

	pack_size_label.text = "Pack Size: %d pcs" % size
	price_label.text = "Price: %.2f / carton" % price
	product_image.texture = texture

	quantity = 1
	update_quantity()


func update_quantity():
	quantity_label.text = str(quantity)
	minus_button.disabled = quantity <= 1
	plus_button.disabled = quantity >= 99


func _on_minus_pressed():
	quantity = max(1, quantity - 1)
	update_quantity()


func _on_plus_pressed():
	quantity = min(99, quantity + 1)
	update_quantity()


func _on_add_pressed():
	if product_name.is_empty():
		return

	add_to_cart.emit(product_name, quantity)
