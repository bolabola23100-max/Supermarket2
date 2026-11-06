extends CanvasLayer

@onready var inventory_ui = $InventoryUI
@onready var supplier_ui = $SupplierUI


# إحصائيات المتجر
@onready var balance_label = $StatsPanel/VBoxContainer/BalanceLabel
@onready var revenue_label = $StatsPanel/VBoxContainer/RevenueLabel
@onready var expenses_label = $StatsPanel/VBoxContainer/ExpensesLabel
@onready var profit_label = $StatsPanel/VBoxContainer/ProfitLabel
@onready var sales_label = $StatsPanel/VBoxContainer/SalesLabel

var money_manager




func _ready():
	set_ltr(self)

	money_manager = get_node("/root/Supermarket/MoneyManager")

	# استقبال إشعارات تغيير الأموال
	money_manager.stats_changed.connect(update_stats)

	# تحديث الإحصائيات عند بداية اللعبة
	update_stats()


# تحديث لوحة الإحصائيات
func update_stats():

	balance_label.text = "Balance: " + str(money_manager.get_money())

	revenue_label.text = "Revenue: " + str(money_manager.get_total_revenue())

	expenses_label.text = "Expenses: " + str(money_manager.get_total_expenses())

	profit_label.text = "Net Profit: " + str(money_manager.get_net_profit())

	sales_label.text = "Sales: " + str(money_manager.get_total_sales())

func set_ltr(node: Node):
	if node is Control:
		node.layout_direction = Control.LAYOUT_DIRECTION_LTR

	for child in node.get_children():
		set_ltr(child)

# فتح المخزون
func open_inventory():

	supplier_ui.hide()

	inventory_ui.show()

	inventory_ui.update_inventory()


# فتح المورد
func open_supplier():

	inventory_ui.hide()

	supplier_ui.show()

	supplier_ui.update_price()
