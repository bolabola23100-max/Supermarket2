extends Button

func _ready():
	visible = false
	pressed.connect(_on_pressed)


func _on_pressed():
	var player = get_tree().get_first_node_in_group("player")

	if player == null:
		return

	player.exit_cashier_mode()
	visible = false
