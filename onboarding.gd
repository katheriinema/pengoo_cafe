extends Node2D

@onready var chat   = $UI/ChatPanel
@onready var label  = chat.get_node("ChatLabel")
@onready var btn    = chat.get_node("OkButton")
@onready var username_input = chat.get_node("UsernameInput")  # 🆕 Your LineEdit

@export var next_scene_path := "res://assets/scenes/Main.tscn"
@export var plot_scene_path := "res://assets/scenes/Plot.tscn"

func _ready():
	randomize()
	label.text = "Welcome! Choose your username and get your first egg."
	btn.text = "Continue"
	btn.connect("pressed", Callable(self, "_on_continue"))

func _on_continue():
	var username = username_input.text.strip_edges()

	if username == "":
		label.text = "❗ Please enter a username."
		return

	# ✅ Save username to GameState
	GameState.player_id = username

	var starter_egg = {
		"id": "starter_%d" % Time.get_unix_time_from_system(),
		"plot_index": 0,
		"type": "taiyaki",
		"rarity": "common",
		"is_starter": true,
		"level": 1,
		"name": ""
	}

	GameState.owned_eggs = [starter_egg]
	GameState.has_onboarded = true

	# ✅ Save to database with username
	GameState.save_to_db()

	chat.hide()
	_spawn_first_egg()

	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file(next_scene_path)

func _spawn_first_egg():
	var packed_scene = load(plot_scene_path)
	if not packed_scene or not packed_scene is PackedScene:
		push_error("❌ Failed to load Plot scene from '%s'" % plot_scene_path)
		return

	var plot = packed_scene.instantiate()
	if not plot or not plot is Node2D:
		push_error("❌ Invalid plot instance")
		return

	plot.penguin_type = "taiyaki"
	plot.panel_description = "Your first legend at the grill!"
	plot.position = get_viewport_rect().size * 0.5

	add_child(plot)

	var sound = get_tree().root.get_node_or_null("Main/UpgradeSound")
	if sound:
		sound.play()
