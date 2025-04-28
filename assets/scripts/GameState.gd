extends Node

# 🔐 Supabase config
const SUPABASE_URL = "https://zefcumwyxmaazdoblhro.supabase.co"
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InplZmN1bXd5eG1hYXpkb2JsaHJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU3NjU1ODUsImV4cCI6MjA2MTM0MTU4NX0.1jfCbrONobwjhSVyhMn098zKQH2Gl9vsLxA5wlWXB1c"

var user_id: String = ""
var access_token: String = ""

# 🧠 Game state
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
var _should_redirect: bool = true
var on_load_callback: Callable = Callable()
var on_save_callback: Callable = Callable()



@onready var http = HTTPRequest.new()

func _ready():
	add_child(http)


# 🔐 Signup & Login
func signup(email: String, password: String):
	var body = { "email": email, "password": password }
	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + access_token,
		"Accept-Encoding: identity" # ✨ ADD THIS
	]
	http.request(SUPABASE_URL + "/auth/v1/signup", headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func login(email: String, password: String):
	var body = { "email": email, "password": password }
	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + access_token,
		"Accept-Encoding: identity" # ✨ ADD THIS
	]
	http.request(SUPABASE_URL + "/auth/v1/token?grant_type=password", headers, HTTPClient.METHOD_POST, JSON.stringify(body))

# ☁️ Save/load progress to/from Supabase
func save_to_db(callback: Callable = Callable()):
	if access_token == "" or user_id == "":
		print("⚠️ Cannot save, user not logged in")
		return

	on_save_callback = callback

	var snapshot = {
		"id": user_id,
		"player_id": player_id,
		"fish_count": fish_inventory,
		"energy": current_energy,
		"penguins": owned_penguins.duplicate(true),
		"coins": coins,
		"has_onboarded": has_onboarded,
		"total_days_played": total_days_played,
		"total_revenue": total_revenue,
		"owned_eggs": owned_eggs.duplicate(true),
		"max_energy": max_energy,
		"for_sale_items": for_sale_items.duplicate(true),
		"last_logout_time": int(Time.get_unix_time_from_system())
	}

	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + access_token,
		"Accept-Encoding: identity" # ✨ ADD THIS
	]

	var url = "%s/rest/v1/user_data?on_conflict=id" % SUPABASE_URL

	# ✨ Connect here to know when save finishes
	http.request_completed.connect(_on_save_to_db_response)

	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(snapshot))
	print("🔁 UPSERT (POST with on_conflict=id) to Supabase:", url)
	print("📦 Payload:", snapshot)

func _on_save_to_db_response(result, code, headers, body):
	http.request_completed.disconnect(_on_save_to_db_response)

	var text = body.get_string_from_utf8()
	print("📦 Save response: ", text)

	if code == 201 or code == 200:
		print("✅ Save successful.")
		if on_save_callback.is_valid():
			on_save_callback.call()
	else:
		push_error("❌ Failed to save user data. Code: %d, Response: %s" % [code, text])

func load_from_db(should_redirect := true):
	_should_redirect = should_redirect

	if access_token == "" or user_id == "":
		print("⚠️ Cannot load, user not logged in")
		return

	print("🌐 Sending load_from_db request...")

	var headers = [
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + access_token,
		"Accept-Encoding: identity" # ✨ ADD THIS
	]
	var url = "%s/rest/v1/user_data?id=eq.%s" % [SUPABASE_URL, user_id]
	http.request(url, headers, HTTPClient.METHOD_GET)
	http.request_completed.connect(_on_load_response)

func _on_load_response(result, code, headers, body):
	http.request_completed.disconnect(_on_load_response)

	var text = body.get_string_from_utf8()
	print("📦 Load user_data response:", text)

	var json = JSON.new()
	if json.parse(text) != OK:
		push_error("❌ Failed to parse user_data response.")
		return

	var data = json.data
	if data == null or not (data is Array):
		push_error("❌ Invalid or empty user_data.")
		return

	if data.size() > 0:
		# ✅ User data exists — sync it
		sync_from_database(data[0])

		if on_load_callback.is_valid():
			on_load_callback.call()
			on_load_callback = Callable()
	else:
		# ❗ No data found — create a brand new save
		print("⚠️ No existing user data found, creating default save...")
		_create_default_user_data()

func _create_default_user_data():
	# Fill in default values
	coins = 500
	fish_inventory = 10
	current_energy = 10
	max_energy = 10
	owned_eggs = []
	owned_penguins = []
	for_sale_items = []
	has_onboarded = false
	total_revenue = 0
	total_days_played = int(Time.get_unix_time_from_system())

	# Save it to Supabase
	save_to_db(Callable(self, "_on_default_save_finished"))

func _on_default_save_finished():
	print("✅ Default save created.")

	if on_load_callback.is_valid():
		on_load_callback.call()
		on_load_callback = Callable()

# 🧠 Local sync logic
func sync_from_database(player_data: Dictionary):
	var raw_name = player_data.get("player_id")
	player_id = raw_name if typeof(raw_name) == TYPE_STRING else ""
	coins = player_data.get("coins", 0)
	fish_inventory = player_data.get("fish_count", 0)
	owned_penguins = player_data.get("penguins", [])
	owned_eggs = player_data.get("owned_eggs", [])
	total_days_played = player_data.get("total_days_played", 0)
	total_revenue = player_data.get("total_revenue", 0)
	has_onboarded = player_data.get("has_onboarded", false)
	current_energy = player_data.get("energy", 10)
	max_energy = player_data.get("max_energy", 10)

	# ⏱️ Offline energy regen
	var last_logout = player_data.get("last_logout_time", 0)
	var now = Time.get_unix_time_from_system()
	var elapsed = now - last_logout
	var regen_interval = 60
	var energy_to_add = int(elapsed / regen_interval)
	if energy_to_add > 0 and current_energy < max_energy:
		current_energy = min(current_energy + energy_to_add, max_energy)
		print("⚡ Offline energy restored: +%d (now %d)" % [energy_to_add, current_energy])

	# 📦 For-sale items
	var raw = player_data.get("for_sale_items", [])
	for_sale_items = raw if typeof(raw) == TYPE_ARRAY else []

# Game economy logic
func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		emit_signal("coins_changed", coins)
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
