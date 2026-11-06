extends SubViewport

@onready var title: Label = $POS_UI/Background/Title
@onready var total_label: Label = $POS_UI/Background/TotalLabel

func _ready() -> void:
	render_target_update_mode = SubViewport.UPDATE_ALWAYS

	title.text = "SUPERMARKET POS"
	total_label.text = "TOTAL: 125.00 EGP"

	var display = get_parent().get_node("POS_Display")
	var material = StandardMaterial3D.new()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = get_texture()

	display.material_override = material

	print("POS DISPLAY CONNECTED")
