extends Control

var database : SQLite

func _ready() -> void:
	database = SQLite.new()
	database.path = "res://penguin_game.db"
	database.open_db()
	_create_player_table()

func _create_player_table():
	var table = {
		"player_id" : {"data_type": "text", "primary_key": true, "not_null": true},
		"password" : {"data_type": "text", "not_null": true},
		"has_onboarded" : {"data_type": "int", "default": 0},
		"owned_money" : {"data_type": "int", "default": 500},
		"total_revenue" : {"data_type": "int", "default": 0},
		"fish_count" : {"data_type": "int", "default": 10},
		"owned_penguins" : {"data_type": "text", "default": "'[]'"},
		"owned_eggs" : {"data_type": "text", "default": "'[]'"},
		"total_days_played" : {"data_type": "int", "default": 0},
		"current_energy": {"data_type": "int", "default": 10},
		"max_energy": {"data_type": "int", "default": 10},
		"last_logout_time": {"data_type": "int", "default": 0}
	}
	database.create_table("players", table)

func try_login(player_id: String, password: String) -> Dictionary:
	var condition = "player_id = '%s'" % player_id
	var rows = database.select_rows("players", condition, ["*"])
	if rows.size() == 0:
		return {"status":"no_user","message":"Username doesn't exist. Please sign up."}

	var user = rows[0]
	if user["password"] != password:
		return {"status":"wrong_password","message":"Wrong password. Try again."}

	# ───── JSON.parse_string returns the actual Array in Godot 4 ─────
	user["owned_penguins"] = JSON.parse_string(user["owned_penguins"])
	user["owned_eggs"]     = JSON.parse_string(user["owned_eggs"])

	return {"status":"success","user":user}




func create_account(player_id: String, password: String) -> Dictionary:
	var condition = "player_id = '%s'" % player_id
	var existing = database.select_rows("players", condition, ["player_id"])

	if existing.size() > 0:
		return {"status": "exists", "message": "Username already exists."}

	var json = JSON.new()
	var data = {
		"player_id": player_id,
		"password": password,
		"has_onboarded": 0,
		"owned_money": 500,
		"total_revenue": 0,
		"fish_count": 10,
		"owned_penguins": json.stringify([]),
		"owned_eggs": json.stringify([]),
		"total_days_played": 0,
		"current_energy": 10,
		"max_energy": 10,
		"last_logout_time": 0
	}
	database.insert_row("players", data)
	return {"status": "created", "message": "Account created! You can now log in."}

func update_player_data(data: Dictionary):
	var json = JSON.new()
	var condition = "player_id = '%s'" % data["player_id"]
	var updated = {
		"owned_money": data["owned_money"],
		"total_revenue": data["total_revenue"],
		"fish_count": data["fish_count"],
		"owned_penguins": json.stringify(data["owned_penguins"]),
		"owned_eggs": json.stringify(data["owned_eggs"]),
		"total_days_played": data["total_days_played"],
		"has_onboarded": data["has_onboarded"],
		"current_energy": data["current_energy"],
		"max_energy": data["max_energy"],
		"last_logout_time": data["last_logout_time"]
	}
	database.update_rows("players", condition, updated)
