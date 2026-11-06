extends RigidBody3D

@export var product_scene: PackedScene     # اسحب مشهد المنتج هنا
@export var count: int = 10
@export var auto_fit: bool = true          # true = الكرتونة تحسب شكلها تلقائياً
@export var columns: int = 5               # بتتستخدم لو auto_fit = false
@export var rows: int = 2                  # بتتستخدم لو auto_fit = false
@export var height_ratio: float = 1.0      # ارتفاع الجدران مقارنة بالمنتجات (1.0 = بنفس الطول)
@export var spacing: float = 0.01
@export var wall_thickness: float = 0.01
@export var padding: float = 0.02
@export var color: Color = Color(0.72, 0.52, 0.32)
@export var product_name: String = ""

var is_open: bool = false

var _max_count: int = 0
var _cols: int = 1
var _rows: int = 1
var _layers: int = 1
var _cell := Vector3.ONE * 0.2
var _item_scale := Vector3.ONE
var _center_off := Vector3.ZERO
var _step := Vector3.ZERO
var _inner := Vector3.ZERO
var _outer := Vector3.ZERO
var _visual: Node3D
var _flap_left: Node3D
var _flap_right: Node3D
var _mat: StandardMaterial3D
var _dummies: Array[Node3D] = []


func _ready():
	add_to_group("products")
	collision_layer = 1
	collision_mask = 1 | 4
	_max_count = count
	_build()


# =========================
# BUILD
# =========================

func _build() -> void:
	# امسح أي Mesh قديم موجود في مشهد الكرتونة
	for c in get_children():
		if c is MeshInstance3D:
			c.queue_free()

	_read_item()

	_mat = StandardMaterial3D.new()
	_mat.albedo_color = color

	_step = Vector3(_cell.x + spacing, _cell.y, _cell.z + spacing)
	_choose_layout()

	_inner = Vector3(_cols * _step.x, _layers * _cell.y, _rows * _step.z)

	var t := wall_thickness
	_outer = Vector3(
		_inner.x + 2.0 * (t + padding),
		_inner.y * height_ratio + t,
		_inner.z + 2.0 * (t + padding))

	print("CARTON: ", _cols, "x", _rows, "x", _layers, " | SIZE: ", _outer)

	_visual = Node3D.new()
	add_child(_visual)

	# الصندوق: قاع + 4 جدران
	_box(_visual, Vector3(_outer.x, t, _outer.z), Vector3(0, -_outer.y / 2.0 + t / 2.0, 0))
	_box(_visual, Vector3(_outer.x, _outer.y, t), Vector3(0, 0, _outer.z / 2.0 - t / 2.0))
	_box(_visual, Vector3(_outer.x, _outer.y, t), Vector3(0, 0, -_outer.z / 2.0 + t / 2.0))
	_box(_visual, Vector3(t, _outer.y, _outer.z - 2.0 * t), Vector3(-_outer.x / 2.0 + t / 2.0, 0, 0))
	_box(_visual, Vector3(t, _outer.y, _outer.z - 2.0 * t), Vector3(_outer.x / 2.0 - t / 2.0, 0, 0))

	# الغطاءان على اليمين والشمال (محور الدوران عند حافة الجدار العلوي)
	_flap_left = Node3D.new()
	_flap_left.position = Vector3(-_outer.x / 2.0, _outer.y / 2.0, 0)
	_visual.add_child(_flap_left)
	_box(_flap_left, Vector3(_outer.x / 2.0, t, _outer.z), Vector3(_outer.x / 4.0, 0, 0))

	_flap_right = Node3D.new()
	_flap_right.position = Vector3(_outer.x / 2.0, _outer.y / 2.0, 0)
	_visual.add_child(_flap_right)
	_box(_flap_right, Vector3(_outer.x / 2.0, t, _outer.z), Vector3(-_outer.x / 4.0, 0, 0))

	# شكل الـ Collision بنفس حجم الصندوق
	var col: CollisionShape3D = null
	for c in get_children():
		if c is CollisionShape3D:
			col = c
			break
	if col == null:
		col = CollisionShape3D.new()
		add_child(col)
	var shape := BoxShape3D.new()
	shape.size = _outer
	col.shape = shape
	col.position = Vector3.ZERO

	# منتجات شكلية جوه الكرتونة (مخفية لحد ما تتفتح)
	for i in _max_count:
		_add_dummy(i)


# يختار أفضل توزيع: أعمدة × صفوف × طبقات، بصندوق أقرب ما يكون لمكعب
func _choose_layout() -> void:
	if not auto_fit:
		_cols = maxi(1, columns)
		_rows = maxi(1, rows)
		_layers = maxi(1, ceili(float(_max_count) / (_cols * _rows)))
		return

	_cols = 1
	_rows = 1
	_layers = 1
	var best_score := INF
	var best_vol := INF

	for layers_try in range(1, _max_count + 1):
		var per_layer := ceili(float(_max_count) / layers_try)
		for c in range(1, per_layer + 1):
			var r := ceili(float(per_layer) / c)
			var size := Vector3(c * _step.x, layers_try * _cell.y, r * _step.z)
			var score := maxf(size.x, maxf(size.y, size.z))
			var vol := size.x * size.y * size.z
			var better := score < best_score - 0.0001
			var tie := absf(score - best_score) <= 0.0001 and vol < best_vol
			if better or tie:
				best_score = score
				best_vol = vol
				_cols = c
				_rows = r
				_layers = layers_try


func _box(parent: Node3D, size: Vector3, pos: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = _mat
	m.mesh = bm
	m.position = pos
	parent.add_child(m)
	return m


# قراءة حجم المنتج من مشهده
func _read_item() -> void:
	_cell = Vector3.ONE * 0.2
	_item_scale = Vector3.ONE
	_center_off = Vector3.ZERO
	if product_scene == null:
		return
	var proto := product_scene.instantiate() as Node3D
	if proto == null:
		return
	_item_scale = proto.scale
	var meshes := proto.find_children("*", "MeshInstance3D", true, false)
	if not meshes.is_empty():
		var mi := meshes[0] as MeshInstance3D
		var aabb := mi.get_aabb()
		_cell = aabb.size * mi.scale * _item_scale
		_center_off = _item_scale * (mi.transform * aabb.get_center())
	proto.free()


@warning_ignore("integer_division")
func _slot(i: int) -> Vector3:
	var per_layer: int = maxi(1, _cols * _rows)
	var layer := i / per_layer
	var idx := i % per_layer
	var col := idx % _cols
	var row := idx / _cols
	return Vector3(
		-_inner.x / 2.0 + _step.x * (col + 0.5),
		-_outer.y / 2.0 + wall_thickness + _cell.y * (layer + 0.5),
		-_inner.z / 2.0 + _step.z * (row + 0.5))


func _add_dummy(i: int) -> void:
	if product_scene == null:
		return
	var proto := product_scene.instantiate() as Node3D
	if proto == null:
		return
	var meshes := proto.find_children("*", "MeshInstance3D", true, false)
	if meshes.is_empty():
		proto.free()
		return

	var d := Node3D.new()
	d.scale = _item_scale
	var m: MeshInstance3D = (meshes[0] as MeshInstance3D).duplicate()
	d.add_child(m)
	proto.free()

	d.position = _slot(i) - _center_off
	d.visible = is_open
	_visual.add_child(d)
	_dummies.append(d)


# =========================
# ANIMATIONS
# =========================

func open() -> void:
	if is_open:
		return
	is_open = true

	var tw := create_tween().set_parallel(true)
	# الغطاء الشمال يتفتح لليسار، واليمين يتفتح لليمين
	tw.tween_property(_flap_left, "rotation:z", deg_to_rad(125.0), 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_flap_right, "rotation:z", deg_to_rad(-125.0), 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# المنتجات تظهر جوه الكرتونة واحد ورا التاني
	for i in _dummies.size():
		var d: Node3D = _dummies[i]
		var final_scale := d.scale
		d.scale = final_scale * 0.01
		d.visible = true
		tw.tween_property(d, "scale", final_scale, 0.25) \
			.set_delay(0.2 + i * 0.03) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func vanish() -> void:
	collision_layer = 0
	collision_mask = 0
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3.ONE * 0.01, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


# =========================
# TAKE / GIVE BACK
# =========================

func take_one() -> RigidBody3D:
	if count <= 0 or product_scene == null:
		return null

	var p := product_scene.instantiate() as RigidBody3D
	if p == null:
		return null

	# نقل اسم المنتج من الكرتونة للمنتج الجديد
	if not product_name.is_empty():
		p.product_name = product_name

	# تسجيل سعر التكلفة للقطعة
	if ProductDB.products.has(p.product_name):
		p.price = ProductDB.get_buy_price(p.product_name)

	p.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	p.freeze = true

	get_tree().current_scene.add_child(p)

	if not _dummies.is_empty():
		var d: Node3D = _dummies.pop_back()
		p.global_transform = d.global_transform
		d.queue_free()
	else:
		p.global_transform = global_transform

	count -= 1

	print("PRODUCT CREATED: ", p.product_name)
	print("PRODUCT COST: ", p.price)

	return p

func give_back(p: Node3D) -> void:
	p.queue_free()
	count += 1
	_add_dummy(count - 1)
