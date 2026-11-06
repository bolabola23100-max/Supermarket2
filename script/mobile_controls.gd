extends CanvasLayer

func _ready():
	set_ltr(self)
	var safe_area = DisplayServer.get_display_safe_area()
	print("SAFE AREA: ", safe_area)


func set_ltr(node: Node):
	if node is Control:
		node.layout_direction = Control.LAYOUT_DIRECTION_LTR

	for child in node.get_children():
		set_ltr(child)
