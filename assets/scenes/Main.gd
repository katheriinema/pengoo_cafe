extends Node2D

@onready var plot_spawns = $WorldLayer/PlotSpawns
@onready var plot_panel_scene = preload("res://assets/scenes/PlotPanel.tscn")
@onready var coin_count = $UI/CoinBox/CoinCount
@onready var coin_icon  = $UI/CoinBox/CoinIcon
@onready var fish_count = $UI/FishBox/FishCount
@onready var fish_icon  = $UI/FishBox/FishIcon
@onready var click_sound = $ClickSound


var spawn_points: Array = []
var plot_panel: Panel = null
var used_plot_indices: Array[int] = []
var autosave_timer := Timer.new()


const TYPE_DESCRIPTIONS = {
	"taiyaki": "Your first legend at the grill!",
	"cream": "Smooth, sweet, and ready to chill.",
	"redbean": "This sweet soul stirs joy!",
	"chocolate": "Indulgence in every bite!",
	"matcha": "Brewed to perfection!"
}

func _ready():
	randomize()

	# 🧠 Setup spawn points
	if plot_spawns:
		for i in range(17):
			var node_name = "SpawnPoint" + str(i)
			var sp = plot_spawns.get_node_or_null(node_name)
			if sp == null:
				push_warning("No %s under PlotSpawns" % node_name)
			spawn_points.append(sp)
	else:
		push_error("PlotSpawns node not found!")

	# Hide onboarding chat if it exists
	var chat_panel = $UI.get_node_or_null("ChatPanel")
	if chat_panel:
		chat_panel.hide()

	# 🪙 Coin & 🐟 Fish UI styling
	coin_icon.texture = load("res://assets/art/icons/coin_icon.png")
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.custom_minimum_size = Vector2(40, 40)

	fish_icon.texture = load("res://assets/art/icons/fish_icon.png")
	fish_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fish_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fish_icon.custom_minimum_size = Vector2(40, 40)

	var font_data = load("res://assets/fonts/Sniglet-Regular.ttf")
	var font = FontFile.new()
	font.font_data = font_data

	var label_settings = LabelSettings.new()
	label_settings.font = font
	label_settings.font_size = 30
	label_settings.font_color = Color(0.1, 0.2, 0.4)

	coin_count.label_settings = label_settings
	fish_count.label_settings = label_settings

	# Initial values
	_update_coin_label(GameState.coins)
	GameState.connect("coins_changed", Callable(self, "_update_coin_label"))

	_update_fish_label(GameState.fish_inventory)
	GameState.connect("fish_changed", Callable(self, "_update_fish_label"))

	# Navigation buttons
	$WorldLayer.get_node("PondButton").connect("pressed", Callable(self, "_on_button_pressed").bind("open_fishing"))
	$WorldLayer.get_node("IglooButton").connect("pressed", Callable(self, "_on_button_pressed").bind("open_profile"))
	$WorldLayer.get_node("ShopButton").connect("pressed", Callable(self, "_on_button_pressed").bind("open_shop"))

	# Plot panel setup
	plot_panel = plot_panel_scene.instantiate()
	$UI.add_child(plot_panel)
	plot_panel.hide()

	# Restore player state
	_load_owned_items()

	# Render selling items
	for item in GameState.for_sale_items:
		CookingManager._emit_selling_item(item["type"], item["payout"], false)

	# ⏱️ Autosave every 30s
	autosave_timer.wait_time = 30
	autosave_timer.one_shot = false
	autosave_timer.autostart = true
	autosave_timer.timeout.connect(_on_autosave)
	add_child(autosave_timer)

func _on_autosave():
	if GameState.access_token != "" and GameState.user_id != "":
		if not GameState.on_save_callback.is_valid():  # 🛡️ Only autosave if no save in progress
			GameState.save_to_db()
			print("💾 Autosaved to Supabase")

func _load_owned_items():
	for i in GameState.owned_eggs.size():
		var data = GameState.owned_eggs[i]
		if typeof(data) != TYPE_DICTIONARY:
			continue
		var plot_index = int(data.get("plot_index", i))
		if used_plot_indices.has(plot_index):
			continue
		_spawn_plot(data, i, false)
		used_plot_indices.append(plot_index)

	for i in GameState.owned_penguins.size():
		var data = GameState.owned_penguins[i]
		var plot_index = int(data.get("plot_index", i))
		if used_plot_indices.has(plot_index):
			continue
		_spawn_plot(data, i, true)
		used_plot_indices.append(plot_index)

func _spawn_plot(data: Dictionary, idx: int, hatched: bool):
	var egg_type = data.get("type", "")
	var rarity = data.get("rarity", "common")
	var egg_id = data.get("id", "")
	var plot_index = int(data.get("plot_index", idx))
	var panel_description = TYPE_DESCRIPTIONS.get(egg_type, "")
	var level = data.get("level", 1)

	if used_plot_indices.has(plot_index):
		return
	
	var Plot = preload("res://assets/scenes/Plot.tscn")
	var plot = Plot.instantiate()
	plot.is_starter = data.get("is_starter", false)
	plot.egg_id = egg_id
	plot.penguin_type = egg_type
	plot.rarity = rarity
	plot.penguin_name = data.get("name", "")
	plot.plot_index = plot_index
	plot.panel_description = panel_description
	plot.level = level

	if plot_index < spawn_points.size():
		var sp = spawn_points[plot_index]
		plot.position = sp.global_position if sp != null else Vector2(50 + plot_index * 80, 200)
	else:
		plot.position = Vector2(50 + plot_index * 80, 200)

	add_child(plot)
	plot.connect("plot_clicked", Callable(self, "open_plot_panel"))
	plot.connect("plot_hatched", Callable(self, "open_plot_panel"))

	if hatched:
		plot.hatch(true)

	CookingManager.register_plot(plot)

func _update_coin_label(new_amount: int):
	coin_count.text = str(new_amount)

func _update_fish_label(new_amount: int):
	fish_count.text = str(new_amount)

func open_plot_panel(plot):
	plot_panel.show_for_plot(plot)

func open_fishing():
	get_tree().change_scene_to_file("res://assets/scenes/Fishing.tscn")

func open_profile():
	get_tree().change_scene_to_file("res://assets/scenes/UserProfile.tscn")

func open_shop():
	get_tree().change_scene_to_file("res://assets/scenes/EggShop.tscn")

func _on_button_pressed(target_function_name: String):
	if click_sound:
		click_sound.play()
	await get_tree().create_timer(0.1).timeout
	call_deferred(target_function_name)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if plot_panel.visible:
			var mouse_pos = get_viewport().get_mouse_position()
			var panel_rect = Rect2(plot_panel.global_position, plot_panel.size)
			if not panel_rect.has_point(mouse_pos):
				plot_panel.hide()
