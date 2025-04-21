extends Control

@export var penguin_card_scene: PackedScene
@onready var penguin_grid       = $RightPanel/PenguinScroll/PenguinGrid

func _ready():
	display_user_info()
	populate_penguins()

func display_user_info():
	# Username
	$LeftPanel/Username.text = "%s’s Village" % GameState.player_id

	# Owned penguin count
	$LeftPanel/DaysPlayed.text = "Days Played: %d" % GameState.total_days_played

	# Owned penguin count
	$LeftPanel/OwnedPenguins.text = "Owned Penguins: %d" % GameState.owned_penguins.size()

	# Total revenue
	$LeftPanel/TotalRevenue.text = "Total Revenue: $%d" % GameState.total_revenue

func populate_penguins():
	# Clear out any old cards
	for child in penguin_grid.get_children():
		child.queue_free()

	# For each owned penguin, instantiate a card
	for penguin in GameState.owned_penguins:
		var card = penguin_card_scene.instantiate()

		# If you store penguins as dicts with name + type:
		#    var name = penguin.name
		#    var icon_path = "res://assets/art/icons/%s.png" % penguin.type
		#
		# If you just store a list of types (e.g. ["taiyaki","matcha"...]):
		var name = penguin   # or fetch a stored name if you added that
		var icon_path = "res://assets/art/icons/%s.png" % penguin

		card.get_node("PenguinImage").texture = load(icon_path)
		card.get_node("PenguinName").text     = name

		penguin_grid.add_child(card)

func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://assets/scenes/Main.tscn")
