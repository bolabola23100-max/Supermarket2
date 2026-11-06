extends Area3D
class_name ShelfZone

var spacing: float = 0.01

var products: Array[Node3D] = []

var _type: String = ""
var _cell := Vector3.ZERO
var _scale := Vector3.ONE
var _center_off := Vector3.ZERO
var _rot := Basis.IDENTITY


func _ready():
	add_to_group("product_points")
	collision_layer = 2
	collision_mask = 0


func _find_box() -> CollisionShape3D:

	for c in get_children():

		if c is CollisionShape3D and c.shape is BoxShape3D:
			return c

	return null


func _zone_size(box: CollisionShape3D) -> Vector3:

	return box.shape.size * box.global_basis.get_scale()


func _measure(product: Node3D) -> void:

	_scale = product.global_basis.get_scale()

	var rot_deg = product.get("shelf_rotation")

	if rot_deg == null:
		rot_deg = Vector3.ZERO

	_rot = Basis.from_euler(Vector3(
		deg_to_rad(rot_deg.x),
		deg_to_rad(rot_deg.y),
		deg_to_rad(rot_deg.z)
	))

	var meshes = product.find_children("*", "MeshInstance3D", true, false)

	if meshes.is_empty():

		_cell = Vector3.ONE * 0.2
		_center_off = Vector3.ZERO
		return

	var mi: MeshInstance3D = meshes[0]

	var aabb := mi.get_aabb()
	var s := mi.global_basis.get_scale()
	var size := aabb.size * s

	_cell = Vector3(
		absf(_rot.x.x) * size.x + absf(_rot.y.x) * size.y + absf(_rot.z.x) * size.z,
		absf(_rot.x.y) * size.x + absf(_rot.y.y) * size.y + absf(_rot.z.y) * size.z,
		absf(_rot.x.z) * size.x + absf(_rot.y.z) * size.y + absf(_rot.z.z) * size.z
	)

	_center_off = _rot * (aabb.get_center() * s)


func _grid(box: CollisionShape3D) -> Vector3i:

	var size := _zone_size(box)

	return Vector3i(
		floori(size.x / (_cell.x + spacing)),
		floori(size.y / _cell.y),
		floori(size.z / (_cell.z + spacing))
	)


# إضافة منتج إلى الرف
func add_product(
	product: Node3D,
	animate: bool = true,
	delay: float = 0.0
) -> bool:

	var box := _find_box()

	if box == null:
		print("SHELF ZONE HAS NO BOX SHAPE")
		return false

	var product_name := str(product.get("product_name"))

	if product_name.is_empty():
		print("PRODUCT HAS NO NAME")
		return false

	# التأكد من أن المنتج موجود في قاعدة البيانات
	if not ProductDB.products.has(product_name):
		print("PRODUCT NOT FOUND IN PRODUCT DB: ", product_name)
		return false

	# تحديد نوع المنتج في الرف
	if products.is_empty():

		_measure(product)
		_type = product.scene_file_path

	elif product.scene_file_path != _type:

		print("DIFFERENT PRODUCT TYPE")
		return false

	# حساب الحد الأقصى للمنتج في جميع الرفوف
	var limit := ProductDB.get_shelf_limit(product_name)

	if limit > 0:

		var stock: Dictionary = ProductDB.count_in_store(product_name)
		var current_count := int(stock["shelves"])

		if current_count >= limit:

			print("PRODUCT SHELF LIMIT REACHED: ", product_name)
			print("CURRENT: ", current_count)
			print("MAXIMUM: ", limit)

			return false

	# التأكد من مساحة الرف نفسه
	var g := _grid(box)
	var capacity := g.x * g.y * g.z

	if products.size() >= capacity:

		print("SHELF FULL")
		return false

	if product.get_parent() != get_tree().current_scene:
		product.reparent(get_tree().current_scene, true)

	products.append(product)

	product.set_meta("shelf_zone", self)

	_place_at(
		product,
		products.size() - 1,
		0.45 if animate else 0.0,
		0.25,
		delay
	)

	return true


# إزالة منتج من الرف
func remove_product(product: Node3D) -> void:

	_kill_tween(product)

	products.erase(product)

	if product.has_meta("shelf_zone"):
		product.remove_meta("shelf_zone")

	if products.is_empty():

		_type = ""

	else:

		_relayout()


# إعادة ترتيب المنتجات
func _relayout() -> void:

	for i in products.size():

		_place_at(products[i], i, 0.2, 0.0, 0.0)


@warning_ignore("integer_division")
func _place_at(
	product: Node3D,
	i: int,
	duration: float,
	arc: float,
	delay: float
) -> void:

	var box := _find_box()

	if box == null:
		return

	var size := _zone_size(box)
	var g := _grid(box)

	var per_layer := g.x * g.z

	if per_layer <= 0:
		return

	var layer := i / per_layer
	var idx := i % per_layer
	var col := idx % g.x
	var row := idx / g.x

	# أول منتج في الخلف -Z
	# المنتجات التالية تتجه للأمام +Z
	var local := Vector3(
		-size.x / 2.0 + (_cell.x + spacing) * (col + 0.5),
		-size.y / 2.0 + _cell.y * (layer + 0.5),
		-size.z / 2.0 + (_cell.z + spacing) * (row + 0.5)
	)

	var frame := Transform3D(
		box.global_basis.orthonormalized(),
		box.global_position
	)

	var center := frame * local

	var b := frame.basis * _rot * Basis.from_scale(_scale)

	var target := Transform3D(
		b,
		center - frame.basis * _center_off
	)

	_kill_tween(product)

	if duration <= 0.0:

		product.global_transform = target
		return

	var from := product.global_transform

	var tw := create_tween()

	product.set_meta("place_tween", tw)

	if delay > 0.0:
		tw.tween_interval(delay)

	tw.tween_method(
		_apply_fly.bind(product, from, target, arc),
		0.0,
		1.0,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# حركة المنتج أثناء وضعه على الرف
func _apply_fly(
	t: float,
	product: Node3D,
	from: Transform3D,
	to: Transform3D,
	arc: float
) -> void:

	if not is_instance_valid(product):
		return

	var pos := from.origin.lerp(to.origin, t)

	pos.y += sin(t * PI) * arc

	var q := from.basis.get_rotation_quaternion().slerp(
		to.basis.get_rotation_quaternion(),
		t
	)

	var s := from.basis.get_scale().lerp(
		to.basis.get_scale(),
		t
	)

	product.global_transform = Transform3D(
		Basis(q) * Basis.from_scale(s),
		pos
	)


# إيقاف حركة المنتج
func _kill_tween(product: Node3D) -> void:

	if product.has_meta("place_tween"):

		var tw = product.get_meta("place_tween")

		if tw != null and tw.is_valid():
			tw.kill()

		product.remove_meta("place_tween")


# الزبون يأخذ آخر منتج (الأقرب للواجهة)
func take_product() -> Node3D:

	if products.is_empty():
		return null

	var p: Node3D = products.back()

	_kill_tween(p)

	products.pop_back()

	if p.has_meta("shelf_zone"):
		p.remove_meta("shelf_zone")

	if products.is_empty():
		_type = ""

	return p


# معرفة آخر منتج بدون سحبه
func peek_product() -> Node3D:

	if products.is_empty():
		return null

	return products.back()


# مكان وقوف الزبون أمام الرف
func get_stand_position(distance: float = 0.8) -> Vector3:

	var box := _find_box()

	if box == null:
		return global_position

	var front := box.global_basis.orthonormalized().z

	return box.global_position + front * (
		_zone_size(box).z / 2.0 + distance
	)
