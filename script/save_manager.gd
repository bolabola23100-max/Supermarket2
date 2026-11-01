extends Node

const SAVE_PATH = "user://savegame.json"

var money_manager
var inventory_manager

var auto_save_timer: float = 0.0
@export var auto_save_interval: float = 10.0


func _ready():

	money_manager = get_node("../MoneyManager")
	inventory_manager = get_node("../InventoryManager")

	# تحميل البيانات عند تشغيل اللعبة
	load_game()

	# حفظ تلقائي عند تغير الأموال
	money_manager.stats_changed.connect(save_game)

	print("SAVE MANAGER INITIALIZED")


func _process(delta):

	auto_save_timer += delta

	if auto_save_timer >= auto_save_interval:

		auto_save_timer = 0.0

		save_game()


# حفظ بيانات اللعبة
func save_game():

	var save_data = {

		"money": money_manager.money,

		"total_sales": money_manager.total_sales,

		"total_revenue": money_manager.total_revenue,

		"total_expenses": money_manager.total_expenses,

		"inventory": inventory_manager.inventory

	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		print("SAVE ERROR!")
		return

	file.store_string(JSON.stringify(save_data))

	file.close()

	print("GAME SAVED SUCCESSFULLY!")


# تحميل بيانات اللعبة
func load_game():

	if not FileAccess.file_exists(SAVE_PATH):

		print("NO SAVE FILE FOUND - NEW GAME")

		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:

		print("LOAD ERROR!")

		return

	var json_text = file.get_as_text()

	file.close()

	var json = JSON.new()

	var error = json.parse(json_text)

	if error != OK:

		print("SAVE FILE ERROR!")

		return

	var save_data = json.data

	if typeof(save_data) != TYPE_DICTIONARY:

		print("INVALID SAVE DATA!")

		return

	# استرجاع الأموال
	money_manager.money = float(save_data.get("money", 0.0))

	money_manager.total_sales = int(save_data.get("total_sales", 0))

	money_manager.total_revenue = float(save_data.get("total_revenue", 0.0))

	money_manager.total_expenses = float(save_data.get("total_expenses", 0.0))

	# استرجاع المخزون
	var saved_inventory = save_data.get("inventory", {})

	if typeof(saved_inventory) == TYPE_DICTIONARY:

		for product_name in inventory_manager.inventory:

			if saved_inventory.has(product_name):

				inventory_manager.inventory[product_name] = int(saved_inventory[product_name])

	# تحديث الواجهة
	money_manager.stats_changed.emit()

	print("GAME LOADED SUCCESSFULLY!")


# حفظ عند إغلاق اللعبة
func _notification(what):

	if what == NOTIFICATION_WM_CLOSE_REQUEST:

		save_game()
