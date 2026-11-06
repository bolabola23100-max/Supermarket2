extends CanvasLayer

var rows: Dictionary = {}
var _panel: PanelContainer
var _timer: Timer


func _ready():
	layer = 100        # فوق كل الواجهات التانية

	# الجذر والـ Center ما بياخدوش اللمس، اللوحة بس هي اللي بتاخده
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	# لوحة بخلفية غامقة وإطار أبيض عشان تبان بوضوح
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.95)
	style.border_color = Color(1, 1, 1, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Inventory"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	for n in ProductDB.names():
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 20)
		vbox.add_child(label)
		rows[n] = label

	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(0, 52)
	close.add_theme_font_size_override("font_size", 22)
	close.pressed.connect(hide)
	vbox.add_child(close)

	# تحديث تلقائي وهي مفتوحة
	_timer = Timer.new()
	_timer.wait_time = 0.5
	_timer.timeout.connect(_on_timer)
	add_child(_timer)
	_timer.start()

	visibility_changed.connect(_on_visibility_changed)

	update_inventory()
	hide()
	print("INVENTORY UI READY")


func _on_timer() -> void:
	if visible:
		update_inventory()


func _on_visibility_changed() -> void:
	if visible:
		update_inventory()
		print("INVENTORY UI OPENED")


func open_inventory() -> void:
	show()


func close_inventory() -> void:
	hide()


func update_inventory() -> void:
	for n in rows:
		var c: Dictionary = ProductDB.count_in_store(n)
		var total: int = c["shelves"] + c["cartons"]
		rows[n].text = "%s:  shelves %d  |  cartons %d  |  total %d" % [n, c["shelves"], c["cartons"], total]


# للتجربة على الكمبيوتر: زر I يفتح ويقفل
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_I:
		visible = not visible
