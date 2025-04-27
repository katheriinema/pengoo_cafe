extends Control

@export var penguin_card_scene : PackedScene
@export var icon_folder        : String = "res://assets/art/penguins/"

@onready var penguin_grid = $RightPanel/PenguinScroll/PenguinGrid
@onready var click_sound = $ClickSound

func _ready():
	display_user_info()
	populate_penguins()

func display_user_info():
	$LeftPanel/Username.text = "%s’s Village" % GameState.player_id
	$LeftPanel/OwnedPenguins.text = "Owned Penguins: %d" % GameState.owned_penguins.size()
	$LeftPanel/TotalRevenue.text = "Total Revenue: $%d" % GameState.total_revenue

	if GameState.total_days_played > 0:
		var timestamp = GameState.total_days_played
		var date = Time.get_datetime_dict_from_unix_time(timestamp)
		var formatted = "%d-%02d-%02d" % [date.year, date.month, date.day]
		$LeftPanel/DaysPlayed.text = "Date Started: %s" % formatted
	else:
		$LeftPanel/DaysPlayed.hide()

func populate_penguins():
	for child in penguin_grid.get_children():
		child.queue_free()

	for entry in GameState.owned_penguins:
		var card = penguin_card_scene.instantiate()
		var p_type = entry.get("type", "")
		var p_name = entry.get("name", p_type.capitalize())

		var name_label = card.get_node("PenguinName")
		name_label.text = p_name
		name_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.6))  # Dark blue

		var icon_path = "%s%s_penguin.png" % [icon_folder, p_type]
		if ResourceLoader.exists(icon_path):
			card.get_node("PenguinImage").texture = load(icon_path)
		else:
			push_warning("❌ Icon not found at: " + icon_path)

		penguin_grid.add_child(card)

func _on_exit_button_pressed():
	if click_sound:
		click_sound.play()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://assets/scenes/Main.tscn")
