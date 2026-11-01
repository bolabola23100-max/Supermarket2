extends CharacterBody3D

@export var move_speed: float = 2.0

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var shopping_basket = $ShoppingBasket

var current_target: Marker3D
var choosing_new_target := false
var has_shopped := false


func _ready():
	global_position = $"../CustomerSpawnPoint".global_position

	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5

	await get_tree().create_timer(1.0).timeout
	choose_random_target()


func _physics_process(_delta):
	if navigation_agent.is_navigation_finished():
		velocity.x = 0
		velocity.z = 0

		if not choosing_new_target:
			choosing_new_target = true
			choose_after_pause()

		return

	var next_position = navigation_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	velocity.y = 0

	move_and_slide()


func choose_after_pause():

	if current_target == $"../ShelfPoint1":

		await get_tree().create_timer(3.0).timeout

		var inventory_manager = get_node("../InventoryManager")
		var selected_product = inventory_manager.get_random_available_product()

		if selected_product != "":
			var success = inventory_manager.take_product(selected_product)

			if success:
				shopping_basket.add_product(selected_product)
				has_shopped = true
		else:
			print("NO PRODUCTS AVAILABLE!")

			has_shopped = true


	elif current_target == $"../CheckoutPoint":

		await get_tree().create_timer(5.0).timeout

		var total = shopping_basket.get_total_price()

		print("======================")
		print("CUSTOMER CHECKOUT")
		print("Products: ", shopping_basket.get_product_count())
		print("Total Price: ", total)
		print("======================")

		if shopping_basket.get_product_count() > 0:
			var money_manager = get_node("../MoneyManager")
			money_manager.add_money(total)

		queue_free()
		return

	else:
		await get_tree().create_timer(1.5).timeout

	choose_random_target()
	choosing_new_target = false


func choose_random_target():

	if not has_shopped:
		current_target = $"../ShelfPoint1"
	else:
		current_target = $"../CheckoutPoint"

	navigation_agent.target_position = current_target.global_position
