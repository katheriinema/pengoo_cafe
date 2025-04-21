extends Control



func _ready():
	if not $VBoxContainer/LoginButton.pressed.is_connected(_on_login_button_pressed):
		$VBoxContainer/LoginButton.pressed.connect(_on_login_button_pressed)

	if not $VBoxContainer/SignupButton.pressed.is_connected(_on_signup_button_pressed):
		$VBoxContainer/SignupButton.pressed.connect(_on_signup_button_pressed)

func _on_login_button_pressed():
	var username = $VBoxContainer/UsernameInput.text.strip_edges()
	var password = $VBoxContainer/PasswordInput.text.strip_edges()

	if username == "" or password == "":
		show_error("Please enter both username and password.")
		return

	var result = SqlController.try_login(username, password)

	match result["status"]:
		"success":
			GameState.player_id = username
			GameState.password  = password
			GameState.sync_from_database(result["user"])
			if GameState.has_onboarded:
				get_tree().change_scene_to_file("res://assets/scenes/Main.tscn")
			else:
				get_tree().change_scene_to_file("res://assets/scenes/Cutscene.tscn")
		"no_user", "wrong_password":
			show_error(result["message"])

func _on_signup_button_pressed():
	var username = $VBoxContainer/UsernameInput.text.strip_edges()
	var password = $VBoxContainer/PasswordInput.text.strip_edges()

	if username == "" or password == "":
		show_error("Please enter both username and password.")
		return

	var result = SqlController.create_account(username, password)
	show_error(result["message"])

func show_error(msg: String):
	$VBoxContainer/ErrorLabel.text = msg
