extends Control

@onready var login_button = $VBoxContainer/LoginButton
@onready var signup_button = $VBoxContainer/SignupButton
@onready var username_input = $VBoxContainer/UsernameInput
@onready var password_input = $VBoxContainer/PasswordInput
@onready var error_label = $VBoxContainer/ErrorLabel
@onready var title_label = $VBoxContainer/TitleLabel
@onready var logo_label = $LogoLabel


func _ready():
	
	# Create and apply custom font
	var font_data = load("res://assets/fonts/Sniglet-ExtraBold.ttf")
	var font = FontFile.new()
	font.font_data = font_data

	var logo_settings = LabelSettings.new()
	logo_settings.font = font
	logo_settings.font_size = 64
	logo_settings.font_color = Color(0.3, 0.3, 0.5)  # soft light blue

	logo_label.label_settings = logo_settings
	logo_label.text = "Pengoo Café"
	logo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Connect buttons
	if not login_button.pressed.is_connected(_on_login_button_pressed):
		login_button.pressed.connect(_on_login_button_pressed)

	if not signup_button.pressed.is_connected(_on_signup_button_pressed):
		signup_button.pressed.connect(_on_signup_button_pressed)

	# Apply cute UI styles
	apply_theme()

func _on_login_button_pressed():
	var username = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()

	if username == "" or password == "":
		show_error("Please enter both username and password.")
		return

	var result = SqlController.try_login(username, password)

	match result["status"]:
		"success":
			GameState.player_id = username
			GameState.password = password
			GameState.sync_from_database(result["user"])
			if GameState.has_onboarded:
				get_tree().change_scene_to_file("res://assets/scenes/Main.tscn")
			else:
				get_tree().change_scene_to_file("res://assets/scenes/Cutscene.tscn")
		"no_user", "wrong_password":
			show_error(result["message"])

func _on_signup_button_pressed():
	var username = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()

	if username == "" or password == "":
		show_error("Please enter both username and password.")
		return

	var result = SqlController.create_account(username, password)
	show_error(result["message"])

func show_error(msg: String):
	error_label.text = msg

func apply_theme():
	# Font setup
	var font_data = load("res://assets/fonts/Sniglet-ExtraBold.ttf")
	var font = FontFile.new()
	font.font_data = font_data

	# Title style
	var title_settings = LabelSettings.new()
	title_settings.font = font
	title_settings.font_size = 36
	title_settings.font_color = Color(0.3, 0.3, 0.5)
	title_label.label_settings = title_settings

	# Button style
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

	# Error text color
	error_label.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	error_label.add_theme_font_override("font", font)
