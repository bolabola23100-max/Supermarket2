extends Node3D

@export var max_slots: int = 8
@export var move_duration: float = 0.35

@onready var slots_parent: Node3D = $ConveyorSlots

var occupied_slots: Dictionary = {}
var moving: bool = false


func _ready() -> void:
	if slots_parent.get_child_count() < max_slots:
		push_error("عدد نقاط الوضع أقل من max_slots!")
		return

	for i in range(4):
		occupied_slots[i] = null


# حساب منتصف كل زوج من النقاط
func get_slot_position(index: int) -> Transform3D:
	var point_a := slots_parent.get_child(index * 2) as Marker3D
	var point_b := slots_parent.get_child(index * 2 + 1) as Marker3D

	var result := point_a.global_transform
	result.origin = (point_a.global_position + point_b.global_position) / 2.0

	return result


func get_free_slot() -> int:
	for i in range(4):
		var product = occupied_slots[i]

		if product == null or not is_instance_valid(product):
			occupied_slots[i] = null
			return i

	return -1


func place_product(product: Node3D) -> bool:
	if product == null or not is_instance_valid(product):
		return false

	var index := get_free_slot()

	if index == -1:
		print("CONVEYOR FULL!")
		return false

	if product is RigidBody3D:
		product.freeze = true
		product.linear_velocity = Vector3.ZERO
		product.angular_velocity = Vector3.ZERO

	if product.get_parent() != null:
		product.reparent(get_tree().current_scene, true)

	product.global_transform = get_slot_position(index)
	occupied_slots[index] = product

	print("PRODUCT PLACED IN POSITION: ", index + 1)

	return true


# تحريك السير بعد المسح
func advance_after_scan(product: Node3D) -> void:
	if moving:
		return

	moving = true

	# تحرير مكان المنتج الممسوح
	for i in range(4):
		if occupied_slots[i] == product:
			occupied_slots[i] = null
			break

	var animations: Array[Tween] = []

	# تحريك المنتجات ناحية الشمال
	for i in range(1, 4):
		var current_product = occupied_slots[i]

		if current_product == null or not is_instance_valid(current_product):
			continue

		var next_index := i - 1

		if occupied_slots[next_index] != null:
			continue

		occupied_slots[i] = null
		occupied_slots[next_index] = current_product

		var target := get_slot_position(next_index)

		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)

		tween.tween_property(
			current_product,
			"global_position",
			target.origin,
			move_duration
		)

		animations.append(tween)

	# انتظار انتهاء كل الحركات
	for tween in animations:
		await tween.finished

	moving = false

	print("CONVEYOR MOVEMENT FINISHED")


func remove_product(product: Node3D) -> void:
	for i in range(4):
		if occupied_slots[i] == product:
			occupied_slots[i] = null
			return


func get_empty_slots() -> int:
	var count := 0

	for i in range(4):
		var product = occupied_slots[i]

		if product == null or not is_instance_valid(product):
			occupied_slots[i] = null
			count += 1

	return count
