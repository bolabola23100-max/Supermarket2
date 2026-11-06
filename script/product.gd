extends RigidBody3D

@export var product_name: String = "Product"
@export var price: float = 10.0
@export var shelf_rotation: Vector3 = Vector3.ZERO   # بالدرجات: لفّة المنتج على الرف


func _ready():
	add_to_group("products")
	collision_layer = 1
	collision_mask = 1 | 4
