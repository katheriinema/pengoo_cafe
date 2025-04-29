extends Control

const PROXY_URL = "https://supabase-proxy-qtrc.vercel.app/api/proxy?url="

@onready var login_button = $VBoxContainer/LoginButton
@onready var signup_button = $VBoxContainer/SignupButton
@onready var username_input = $VBoxContainer/UsernameInput
@onready var password_input = $VBoxContainer/PasswordInput
@onready var error_label = $ErrorLabel
@onready var title_label = $VBoxContainer/TitleLabel
@onready var logo_label = $LogoLabel
@onready var click_sound = $ClickSound
@onready var http = $HTTPRequest

func _ready():
	var font_data = load("res://assets/fonts/Sniglet-ExtraBold.ttf")
	var font = FontFile.new()
	font.font_data = font_data

	var logo_settings = LabelSettings.new()
	logo_settings.font = font
	logo_settings.font_size = 64
	logo_settings.font_color = Color(0.3, 0.3, 0.5)

	logo_label.label_settings = logo_settings
	logo_label.text = "Pengoo Café"
	logo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	username_input.focus_mode = Control.FOCUS_ALL
	username_input.editable = true
	password_input.focus_mode = Control.FOCUS_ALL
	password_input.editable = true
	password_input.secret = true

	username_input.gui_input.connect(func(event):
		if event is InputEventScreenTouch and event.pressed:
			username_input.show_virtual_keyboard()
	)

	password_input.gui_input.connect(func(event):
		if event is InputEventScreenTouch and event.pressed:
			password_input.show_virtual_keyboard()
	)
	

	if not login_button.pressed.is_connected(_on_login_button_pressed):
		login_button.pressed.connect(_on_login_button_pressed)
	if not signup_button.pressed.is_connected(_on_signup_button_pressed):
		signup_button.pressed.connect(_on_signup_button_pressed)

	apply_theme()

func _create_initial_user_data():
	var create_http = HTTPRequest.new()
	add_child(create_http)

	var headers = [
		"Content-Type: application/json",
		"apikey: " + GameState.SUPABASE_KEY,
		"Authorization: Bearer " + GameState.access_token
	]

	var body = {
		"id": GameState.user_id,
		"coins": 500,
		"fish_count": 10,
		"energy": 10,
		"max_energy": 10,
		"owned_eggs": [],
		"penguins": [],
		"for_sale_items": [],
		"has_onboarded": false,
		"total_revenue": 0,
		"total_days_played": int(Time.get_unix_time_from_system()),
		"last_logout_time": int(Time.get_unix_time_from_system())
	}

	var url = PROXY_URL + GameState.SUPABASE_URL + "/rest/v1/user_data"

	create_http.request_completed.connect(_on_create_user_data_response.bind(create_http))
	create_http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_create_user_data_response(result, code, headers, body, create_http):
	create_http.queue_free()

	var text = body.get_string_from_utf8()
	print("📥 Create user_data Response [%d]: %s" % [code, text])

	if code == 201 or code == 200:
		print("✅ New user data created successfully.")
	elif code == 409:
		print("⚠️ User data already exists, skipping creation.")
	else:
		push_error("❌ Failed to create initial user data: %s" % text)

	GameState.on_load_callback = Callable(self, "_on_user_data_loaded")
	GameState.load_from_db()

func _on_login_button_pressed():
	var email = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	if click_sound:
		click_sound.play()
	if email == "" or password == "":
		show_error("Please enter both username and password.")
		return

	var body = {
		"email": email,
		"password": password
	}
	var headers = [
		"Content-Type: application/json",
		"apikey: " + GameState.SUPABASE_KEY
	]

	var url = PROXY_URL + GameState.SUPABASE_URL + "/auth/v1/token?grant_type=password"

	http.request_completed.connect(_on_login_response)
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_signup_button_pressed():
	var email = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	if click_sound:
		click_sound.play()
	if email == "" or password == "":
		show_error("Please enter both username and password.")
		return

	var body = {
		"email": email,
		"password": password
	}
	var headers = [
		"Content-Type: application/json",
		"apikey: " + GameState.SUPABASE_KEY
	]

	var url = PROXY_URL + GameState.SUPABASE_URL + "/auth/v1/signup"

	http.request_completed.connect(_on_signup_response)
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_login_response(result, code, headers, body):
	http.request_completed.disconnect(_on_login_response)

	var text = body.get_string_from_utf8()
	print("📥 Login Response [%d]: %s" % [code, text])

	var json = JSON.new()
	if json.parse(text) != OK:
		show_error("Failed to parse login response.")
		return

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		show_error("Invalid login response format.")
		return

	if code == 200 or code == 201:
		if data.has("access_token"):
			GameState.access_token = data["access_token"]
			GameState.user_id = data["user"]["id"]
			GameState.on_load_callback = Callable(self, "_on_user_data_loaded")
			GameState.load_from_db()
		else:
			show_error("Unexpected response from server (login).")
	else:
		if data.has("error"):
			show_error(data["error"]["message"])
		else:
			show_error("Login error %d: %s" % [code, text])

func _on_signup_response(result, code, headers, body):
	http.request_completed.disconnect(_on_signup_response)

	var text = body.get_string_from_utf8()
	print("📥 Signup Response [%d]: %s" % [code, text])

	var json = JSON.new()
	if json.parse(text) != OK:
		show_error("Failed to parse signup response.")
		return

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		show_error("Invalid signup response format.")
		return

	if code == 200 or code == 201:
		if data.has("access_token"):
			GameState.access_token = data["access_token"]
			GameState.user_id = data["user"]["id"]
			_create_initial_user_data()
		else:
			show_error("Unexpected response from server (signup).")
	else:
		if data.has("error"):
			show_error(data["error"]["message"])
		else:
			show_error("Signup error %d: %s" % [code, text])

func show_error(msg: String):
	error_label.text = msg

func apply_theme():
	var font_data = load("res://assets/fonts/Sniglet-ExtraBold.ttf")
	var font = FontFile.new()
	font.font_data = font_data

	var title_settings = LabelSettings.new()
	title_settings.font = font
	title_settings.font_size = 36
	title_settings.font_color = Color(0.3, 0.3, 0.5)
	title_label.label_settings = title_settings

	var default_style = StyleBoxFlat.new()
	default_style.bg_color = Color(0.75, 0.85, 1.0)
	default_style.corner_radius_top_left = 12
	default_style.corner_radius_top_right = 12
	default_style.corner_radius_bottom_left = 12
	default_style.corner_radius_bottom_right = 12

	var hover_style = default_style.duplicate()
	hover_style.bg_color = Color(0.9, 1.0, 1.0)

	for button in [login_button, signup_button]:
		button.add_theme_stylebox_override("normal", default_style)
		button.add_theme_stylebox_override("hover", hover_style)
		button.add_theme_font_override("font", font)
		button.add_theme_color_override("font_color", Color(0.2, 0.2, 0.3))

	error_label.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	error_label.add_theme_font_override("font", font)

func _on_user_data_loaded():
	print("✅ GameState finished loading")

	if not GameState.has_onboarded:
		print("🧭 First-time user — going to Cutscene...")
		get_tree().change_scene_to_file("res://assets/scenes/Cutscene.tscn")
	else:
		print("🌍 User is onboarded — proceeding to Main...")
		get_tree().change_scene_to_file("res://assets/scenes/Main.tscn")
