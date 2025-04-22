# res://assets/scripts/Onboarding.gd
extends Node2D

@onready var chat   = $UI/ChatPanel
@onready var label  = chat.get_node("ChatLabel")
@onready var btn    = chat.get_node("OkButton")

@export var next_scene_path := "res://assets/scenes/Main.tscn"
@export var plot_scene_path := "res://assets/scenes/Plot.tscn"

func _ready():
	randomize()
	
	# Setup the welcome dialog
	label.text = "Welcome to %s! Here's your first egg." % GameState.player_id
	btn.text   = "Continue"
	btn.connect("pressed", Callable(self, "_on_continue"))

func _on_continue():
	chat.hide()
	_spawn_first_egg()
	
	var starter_egg = {
	"id": "starter_%d" % Time.get_unix_time_from_system(),
	"plot_index": 0,
	"type": "taiyaki",
	"rarity": "common",
	"is_starter": true
	}
	GameState.owned_eggs = [starter_egg]
	GameState.has_onboarded = true
	GameState.save_to_db()


	# Jump to Main
	get_tree().change_scene_to_file(next_scene_path)

func _spawn_first_egg():
	# 1) Load the PackedScene
	var packed_scene = load(plot_scene_path)
	if not packed_scene or not packed_scene is PackedScene:
		push_error("❌ Failed to load Plot scene from '%s'" % plot_scene_path)
		return

	# 2) Instantiate
	var plot = packed_scene.instantiate()
	if not plot:
		push_error("❌ PackedScene.instantiate() returned null")
		return

	# 3) Must be a Node2D to set .position
	if not plot is Node2D:
		push_error("❌ Plot instance is not a Node2D")
		return

	# 4) Configure
	plot.penguin_type      = "taiyaki"
	plot.panel_description = "Your first legend at the grill!"
	plot.position          = get_viewport_rect().size * 0.5

	# 5) Add to this scene
	add_child(plot)
