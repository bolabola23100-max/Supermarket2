extends Control

@onready var milk_label = $Panel/VBoxContainer/MilkLabel
@onready var bread_label = $Panel/VBoxContainer/BreadLabel
@onready var juice_label = $Panel/VBoxContainer/JuiceLabel

@onready var refresh_button = $Panel/VBoxContainer/RefreshButton
@onready var close_button = $Panel/VBoxContainer/CloseButton

var inventory_manager


func _ready():
	inventory_manager = get_node("/root/Supermarket/InventoryManager")

	refresh_button.pressed.connect(update_inventory)
	close_button.pressed.connect(close_inventory)

	update_inventory()
	hide()

func update_inventory():
	milk_label.text = "Milk: " + str(inventory_manager.get_stock("Milk"))
	bread_label.text = "Bread: " + str(inventory_manager.get_stock("Bread"))
	juice_label.text = "Juice: " + str(inventory_manager.get_stock("Juice"))


func close_inventory():
	hide()
