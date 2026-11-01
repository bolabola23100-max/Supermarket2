extends Button


func _ready():
	pressed.connect(_on_pressed)


func _on_pressed():

	var player = get_tree().get_first_node_in_group("player")

	if player == null:
		print("PLAYER NOT FOUND!")
		return

	var interaction_manager = player.get_node_or_null("InteractionManager")

	if interaction_manager == null:
		print("INTERACTION MANAGER NOT FOUND!")
		return

	interaction_manager.interact()
