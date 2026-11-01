extends Node3D

@export var spawn_interval: float = 8.0
@export var max_customers: int = 5

var spawn_timer: float = 0.0

var customer_scene = preload("res://scene/customer.tscn")

func _ready():
	spawn_customer()


func _process(delta):
	var customers = get_tree().get_nodes_in_group("customers")

	if customers.size() >= max_customers:
		return

	spawn_timer += delta

	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_customer()


func spawn_customer():
	var customer = customer_scene.instantiate()

	customer.add_to_group("customers")

	get_parent().add_child.call_deferred(customer)
