# res://assets/scripts/UserProfile.gd
extends Control

@export var penguin_card_scene: PackedScene
@onready var penguin_grid = $RightPanel/PenguinScroll/PenguinGrid

func _ready():
	display_user_info()
	populate_penguins()

func display_user_info():
	$LeftPanel/Username.text       = "%s’s Village" % GameState.player_id
	$LeftPanel/OwnedPenguins.text  = "Owned Penguins: %d" % GameState.owned_penguins.size()
	$LeftPanel/TotalRevenue.text   = "Total Revenue: $%d" % GameState.total_revenue
	# If you have a date_started field:
	if GameState.has_method("days_played") and GameState.total_days_played != 0:
		$LeftPanel/DaysPLayed.text = "Date Started: %s" % GameState.total_days_played
	else:
		$LeftPanel/DaysPlayed.hide()

func populate_penguins():
	# clear existing cards
	for child in penguin_grid.get_children():
		child.queue_free()

	# create a card for each penguin entry
	for entry in GameState.owned_penguins:
		var card = penguin_card_scene.instantiate()
		
		# extract type and optional name
		var p_type = entry.get("type", "")
		var p_name = entry.get("name", "")
		if p_name == "":
			p_name = p_type.capitalize()
		card.get_node("PenguinName").text = p_name
		
		# load icon
		var icon_path = "res://assets/art/icons/%s.png" % p_type
		if ResourceLoader.exists(icon_path):
			card.get_node("PenguinImage").texture = load(icon_path)
		
		card.get_node("PenguinName").text = p_name
		penguin_grid.add_child(card)

func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://assets/scenes/Main.tscn")
