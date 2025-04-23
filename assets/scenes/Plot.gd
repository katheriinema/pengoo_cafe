extends Node2D

signal plot_clicked(plot)
signal plot_hatched(plot)

@export var egg_scene        : PackedScene = preload("res://assets/scenes/Egg.tscn")
@export var penguin_type     : String      = "taiyaki"
@export var panel_description: String      = "Your first penguin!!!"
@export var icon_folder      : String      = "res://assets/art/icons/"

const FISH_TO_HATCH = 3

var fish_fed     : int    = 0
var is_hatched   : bool   = false
var penguin_name : String = ""
var egg_id       : String = ""  # set by Main.gd when spawning

var egg_node         : Node2D
var penguin_sprite   : Sprite2D
var plot_index       : int = 0
var rarity           : String = "common"
var is_starter       : bool = false

func _ready():
	# Spawn the egg visual
	egg_node = egg_scene.instantiate()
	egg_node.position = $EggSpawnPoint.position
	add_child(egg_node)

	add_to_group("plots")
	$Area2D.connect("input_event", Callable(self, "_on_area_input"))

func _on_area_input(_v, event, _s):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("plot_clicked", self)

func feed():
	if is_hatched:
		return
	if not GameState.spend_fish():
		emit_signal("plot_clicked", self)
		return
	fish_fed += 1
	if fish_fed >= FISH_TO_HATCH:
		hatch()
	else:
		emit_signal("plot_clicked", self)

func hatch(skip_persist: bool = false):
	if is_hatched:
		return
	is_hatched = true

	# Remove egg
	if egg_node:
		egg_node.queue_free()

	# Add penguin sprite using correct icon
	penguin_sprite = Sprite2D.new()
	var icon_path = "%s%s.png" % [icon_folder, penguin_type]
	if ResourceLoader.exists(icon_path):
		penguin_sprite.texture = load(icon_path)
	else:
		push_error("🐧 Could not load penguin icon: " + icon_path)

	penguin_sprite.position = $EggSpawnPoint.position

	# 🔽 Scale it down to fit the plot area nicely
	penguin_sprite.scale = Vector2(0.15, 0.15)  # Adjust as needed (0.1–0.3 usually looks good)

	add_child(penguin_sprite)

	# Persist hatch change
	if not skip_persist:
		for entry in GameState.owned_eggs:
			var entry_id = ""
			if typeof(entry) == TYPE_DICTIONARY:
				entry_id = entry["id"]
			else:
				entry_id = entry

			if entry_id == egg_id:
				GameState.owned_eggs.erase(entry)
				break

		GameState.owned_penguins.append({
			"id": egg_id,
			"type": penguin_type,
			"rarity": rarity,
			"name": "",
			"plot_index": plot_index,
			"is_starter": is_starter
		})
		GameState.save_to_db()
		emit_signal("plot_hatched", self)

	# Register with CookingManager
	if has_node("/root/CookingManager"):
		var cm = get_node("/root/CookingManager")
		cm.register_plot(self)

func sell():
	if is_starter:
		print("❌ Cannot sell the starter penguin.")
		return

	for entry in GameState.owned_penguins:
		var entry_id: String
		if typeof(entry) == TYPE_DICTIONARY:
			entry_id = entry["id"]
		else:
			entry_id = entry
		if entry_id == egg_id:
			GameState.owned_penguins.erase(entry)
			break

	GameState.add_coins(100)
	queue_free()

func is_egg() -> bool:
	return not is_hatched

func needs_name() -> bool:
	return is_hatched and penguin_name == ""

func set_penguin_name(new_name: String):
	penguin_name = new_name.strip_edges()
	for entry in GameState.owned_penguins:
		if typeof(entry) == TYPE_DICTIONARY and entry.get("id") == egg_id:
			entry["name"] = penguin_name
			break
	GameState.save_to_db()

func get_display_texture() -> Texture2D:
	if is_egg():
		return egg_node.get_node("Sprite2D").texture
	else:
		return penguin_sprite.texture

func get_description() -> String:
	return "Fish fed: %d / %d" % [fish_fed, FISH_TO_HATCH]

func get_panel_description() -> String:
	return panel_description
