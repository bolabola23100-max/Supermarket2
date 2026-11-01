extends Node

signal stats_changed

var money: float = 0.0

var total_sales: int = 0
var total_revenue: float = 0.0
var total_expenses: float = 0.0


# إضافة فلوس من بيع المنتجات
func add_money(amount: float):

	if amount <= 0:
		return

	money += amount
	total_revenue += amount
	total_sales += 1

	stats_changed.emit()

	print("======================")
	print("SALE COMPLETED")
	print("SALE AMOUNT: ", amount)
	print("TOTAL REVENUE: ", total_revenue)
	print("TOTAL SALES: ", total_sales)
	print("CURRENT MONEY: ", money)
	print("NET PROFIT: ", get_net_profit())
	print("======================")


# خصم فلوس من المتجر
func spend_money(amount: float) -> bool:

	if amount <= 0:
		return false

	if money < amount:
		print("NOT ENOUGH MONEY!")
		return false

	money -= amount
	total_expenses += amount

	stats_changed.emit()

	print("======================")
	print("MONEY SPENT: ", amount)
	print("TOTAL EXPENSES: ", total_expenses)
	print("REMAINING MONEY: ", money)
	print("NET PROFIT: ", get_net_profit())
	print("======================")

	return true


# الرصيد الحالي
func get_money() -> float:
	return money


# إجمالي المبيعات
func get_total_revenue() -> float:
	return total_revenue


# إجمالي المصروفات
func get_total_expenses() -> float:
	return total_expenses


# صافي الربح
func get_net_profit() -> float:
	return total_revenue - total_expenses


# عدد عمليات البيع
func get_total_sales() -> int:
	return total_sales
