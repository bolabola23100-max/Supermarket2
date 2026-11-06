extends Button

var _manager: Node


func _ready():
	focus_mode = Control.FOCUS_NONE   # يمنع الزر من أخذ الـ focus
	button_down.connect(_on_pressed)  # يستجيب لحظة اللمس بدل لحظة رفع الإصبع


func _on_pressed():
	if _manager == null:
		var player = get_tree().get_first_node_in_group("player")
		if player == null:
			print("PLAYER NOT FOUND!")
			return
		_manager = player.get_node_or_null("InteractionManager")

	if _manager == null:
		print("INTERACTION MANAGER NOT FOUND!")
		return

	_manager.interact()
