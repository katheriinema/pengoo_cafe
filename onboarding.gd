extends Control

func _ready():
	if not $VBoxContainer/Finish.pressed.is_connected(_on_finish_pressed):
		$VBoxContainer/Finish.pressed.connect(_on_finish_pressed)

func _on_finish_pressed():
	GameState.has_onboarded = true
	GameState.save_to_db()
	get_tree().change_scene_to_file("res://assets/scenes/Main.tscn")  # or Main.tscn if you prefer
