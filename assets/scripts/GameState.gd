extends Node

signal coins_changed(new_amount)
signal fish_changed(new_amount)
signal energy_changed(current, max)

var player_id: String = "" 
var password: String = ""  
var has_onboarded: bool = false
var coins: int = 0
var total_revenue: int = 0
var fish_inventory: int = 0
var owned_penguins: Array = []
var owned_eggs: Array = []
var total_days_played: int = 0
var current_energy: int = 10
var max_energy: int = 10
var for_sale_items: Array = []

func sync_from_database(player_data: Dictionary):
	coins = player_data.get("owned_money", 0)
	fish_inventory = player_data.get("fish_count", 0)
	owned_penguins = player_data.get("owned_penguins", [])
	owned_eggs = player_data.get("owned_eggs", [])
	total_days_played = player_data.get("total_days_played", 0)
	total_revenue = player_data.get("total_revenue", 0)
	has_onboarded = player_data.get("has_onboarded", 0) == 1

	current_energy = player_data.get("current_energy", 10)
	max_energy = player_data.get("max_energy", 10)

	# ⏱️ Offline energy regen
	var last_logout = player_data.get("last_logout_time", 0)
	var now = Time.get_unix_time_from_system()
	var elapsed = now - last_logout
	var regen_interval = 60  # 1 per 60s
	var energy_to_add = int(elapsed / regen_interval)

	if energy_to_add > 0 and current_energy < max_energy:
		current_energy = min(current_energy + energy_to_add, max_energy)
		print("Offline energy restored: +%d (now %d)" % [energy_to_add, current_energy])

	# 📦 Restore for_sale_items
	var raw = player_data.get("for_sale_items", "[]")
	var json = JSON.new()
	if json.parse(raw) == OK and typeof(json.data) == TYPE_ARRAY:
		for_sale_items = json.data
	else:
		for_sale_items = []

func get_save_data() -> Dictionary:
	return {
		"player_id": player_id,
		"password": "",
		"owned_money": coins,
		"total_revenue": total_revenue,
		"fish_count": fish_inventory,
		"owned_penguins": owned_penguins,
		"owned_eggs": owned_eggs,
		"total_days_played": total_days_played,
		"has_onboarded": int(has_onboarded),
		"current_energy": current_energy,
		"max_energy": max_energy,
		"last_logout_time": Time.get_unix_time_from_system(),
		"for_sale_items": JSON.stringify(for_sale_items)
	}

func save_to_db():
	var data = get_save_data()
	SqlController.update_player_data(data)

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		emit_signal("coins_changed", coins)
		save_to_db()
		return true
	return false

func add_coins(amount: int):
	coins += amount
	emit_signal("coins_changed", coins)
	save_to_db()

func add_fish(amount: int = 1):
	fish_inventory += amount
	emit_signal("fish_changed", fish_inventory)
	save_to_db()

func spend_fish(amount: int = 1) -> bool:
	if fish_inventory >= amount:
		fish_inventory -= amount
		emit_signal("fish_changed", fish_inventory)
		save_to_db()
		return true
	return false

func restore_energy(amount: int = 1):
	current_energy = min(current_energy + amount, max_energy)
	emit_signal("energy_changed", current_energy, max_energy)
	save_to_db()

func use_energy(amount: int = 1) -> bool:
	if current_energy >= amount:
		current_energy -= amount
		emit_signal("energy_changed", current_energy, max_energy)
		save_to_db()
		return true
	return false

func get_used_plot_indices() -> Array[int]:
	var used: Array[int] = []
	for egg in owned_eggs:
		if typeof(egg) == TYPE_DICTIONARY and egg.has("plot_index"):
			used.append(int(egg["plot_index"]))
	for penguin in owned_penguins:
		if typeof(penguin) == TYPE_DICTIONARY and penguin.has("plot_index"):
			used.append(int(penguin["plot_index"]))
	return used
