extends Node2D

@onready var chat               = $UI/ChatPanel
@onready var label              = chat.get_node("ChatLabel")
@onready var input              = chat.get_node("NameInput")
@onready var btn                = chat.get_node("OkButton")
@onready var spawn_points       = [
	$PlotSpawns/SpawnPoint0,
	$PlotSpawns/SpawnPoint1,
	$PlotSpawns/SpawnPoint2,
	$PlotSpawns/SpawnPoint3,
]
@onready var plot_panel_scene   = preload("res://assets/scenes/PlotPanel.tscn")
var plot_panel: Panel = null

@onready var pond_button = $WorldLayer/PondButton
@onready var fishing_scene = preload("res://assets/scenes/Fishing.tscn")
var fishing_node: Node = null

@onready var igloo_button = $WorldLayer/IglooButton
@onready var profile_scene = preload("res://assets/scenes/UserProfile.tscn")
var igloo_node: Node = null

@onready var shop_button = $WorldLayer/ShopButton
@onready var shop_scene = preload("res://assets/scenes/EggShop.tscn")
var shop_node: Node = null

@onready var coin_label         = $UI/CoinLabel

var used_indices    := []
var village_name    := "Pingooville"  # Default name

func _ready():
	randomize()

	# Show welcome message
	label.text = "Welcome to %s! Here's your first egg." % village_name
	input.visible = false
	btn.visible = true
	btn.text = "Continue"
	btn.connect("pressed", Callable(self, "_on_continue"))

	# Create and hide the plot panel
	plot_panel = plot_panel_scene.instantiate()
	$UI.add_child(plot_panel)
	plot_panel.hide()

	# Initialize coin label and fish label
	_update_coin_label(GameState.coins)
	GameState.connect("coins_changed", Callable(self, "_update_coin_label"))
	$UI/FishLabel.text = "Fish: %d" % GameState.fish_inventory
	GameState.connect("fish_changed", Callable(self, "_update_fish_label"))

	# Button connections
	pond_button.connect("pressed", Callable(self, "open_fishing"))
	igloo_button.connect("pressed", Callable(self, "open_profile"))
	shop_button.connect("pressed", Callable(self, "open_shop"))

func _on_continue():
	chat.hide()
	spawn_plot()

func spawn_plot():
	var idx = used_indices.size()
	if idx >= spawn_points.size():
		push_error("No more free plot slots!")
		return
	used_indices.append(idx)

	var PlotScene = preload("res://assets/scenes/Plot.tscn")
	var plot = PlotScene.instantiate()

	# Assign types & descriptions
	if idx == 0:
		plot.penguin_type       = "taiyaki"
		plot.panel_description  = "Your first legend at the grill!"
	else:
		var types = ["redbean", "matcha", "chocolate"]
		var choice = types[randi() % types.size()]
		plot.penguin_type = choice
		match choice:
			"redbean":
				plot.panel_description = "This sweet soul stirs joy!"
			"matcha":
				plot.panel_description = "Brewed to perfection!"
			"chocolate":
				plot.panel_description = "Indulgence in every bite!"

	# Position
	if idx == 0:
		plot.position = get_viewport_rect().size / 2
	else:
		plot.position = spawn_points[idx].position

	add_child(plot)
	plot.connect("plot_clicked", Callable(self, "open_plot_panel"))
	plot.connect("plot_hatched", Callable(self, "open_plot_panel"))

func open_plot_panel(plot):
	plot_panel.show_for_plot(plot)

func _update_coin_label(new_amount: int):
	coin_label.text = "Coins: %d" % new_amount

func _update_fish_label(new_amount: int):
	$UI/FishLabel.text = "Fish: %d" % new_amount

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if plot_panel.visible:
			var mouse_pos   = get_viewport().get_mouse_position()
			var panel_pos   = plot_panel.global_position
			var panel_size  = plot_panel.size
			var panel_rect  = Rect2(panel_pos, panel_size)
			if not panel_rect.has_point(mouse_pos):
				plot_panel.hide()

func open_fishing():
	get_tree().change_scene_to_file("res://assets/scenes/Fishing.tscn")

func open_profile():
	get_tree().change_scene_to_file("res://assets/scenes/UserProfile.tscn")

func open_shop():
	get_tree().change_scene_to_file("res://assets/scenes/EggShop.tscn")
