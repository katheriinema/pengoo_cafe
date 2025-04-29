extends Node2D

signal plot_clicked(plot)
signal plot_hatched(plot)

@export var egg_scene: PackedScene = preload("res://assets/scenes/Egg.tscn")
@export var penguin_type: String = "taiyaki"
@export var panel_description: String = "Your first penguin!!!"
@export var icon_folder: String = "res://assets/art/icons/"

const FISH_TO_HATCH = 3
const MAX_LEVEL = 99
const BASE_UPGRADE_COST = 100
const UPGRADE_MULTIPLIER = 1.2
const RARITY_MULTIPLIERS = {
	"common": 1.0,
	"rare": 1.5,
	"epic": 2.5
}

var fish_fed: int = 0
var is_hatched: bool = false
var penguin_name: String = ""
var egg_id: String = ""
var plot_index: int = 0
var rarity: String = "common"
var is_starter: bool = false
var level: int = 1

var egg_node: Node2D
var penguin_sprite: Sprite2D
var overlay_node: Node2D

@onready var progress_bar: ProgressBar = $ProgressBar

func _ready():
	egg_node = egg_scene.instantiate()
	egg_node.position = $EggSpawnPoint.position
	egg_node.rarity = rarity
	add_child(egg_node)

	add_to_group("plots")
	$Area2D.connect("input_event", Callable(self, "_on_area_input"))

	progress_bar.visible = false
	progress_bar.value = 0.0

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

	var sound = get_tree().root.get_node_or_null("Main/UpgradeSound")
	if sound:
		sound.play()

func hatch(skip_persist: bool = false):
	if is_hatched:
		return
	is_hatched = true

	if egg_node:
		egg_node.queue_free()

	penguin_sprite = Sprite2D.new()
	var icon_path = "res://assets/art/penguins/%s_penguin.png" % penguin_type
	if ResourceLoader.exists(icon_path):
		penguin_sprite.texture = load(icon_path)
	else:
		push_error("🐧 Could not load penguin icon: " + icon_path)

	penguin_sprite.position = $EggSpawnPoint.position + Vector2(10, -10)
	penguin_sprite.scale = Vector2(0.1, 0.1)
	add_child(penguin_sprite)

	load_overlay()

	if not skip_persist:
		for entry in GameState.owned_eggs:
			if typeof(entry) == TYPE_DICTIONARY and entry["id"] == egg_id:
				GameState.owned_eggs.erase(entry)
				break

		GameState.owned_penguins.append({
			"id": egg_id,
			"type": penguin_type,
			"rarity": rarity,
			"name": penguin_name,
			"level": level,
			"plot_index": plot_index,
			"is_starter": is_starter
		})
		GameState.save_to_db()
		emit_signal("plot_hatched", self)

	if has_node("/root/CookingManager"):
		var cm = get_node("/root/CookingManager")
		cm.register_plot(self)

func sell():
	if is_starter:
		print("❌ Cannot sell the starter penguin.")
		return

	var rarity_multiplier = RARITY_MULTIPLIERS.get(rarity, 1.0)
	var sell_price = int(rarity_multiplier * (level * level * UPGRADE_MULTIPLIER + BASE_UPGRADE_COST))

	GameState.add_coins(sell_price)
	GameState.total_revenue += sell_price
	GameState.owned_penguins = GameState.owned_penguins.filter(func(p): return p["id"] != egg_id)
	GameState.save_to_db()
	queue_free()

	var sound = get_tree().root.get_node_or_null("Main/SellSound")
	if sound:
		sound.play()

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
	return "Level %d • %s" % [level, panel_description]

func load_overlay():
	if overlay_node:
		overlay_node.queue_free()

	var overlay_path = "res://assets/art/penguin_items/%s_items.png" % penguin_type
	if ResourceLoader.exists(overlay_path):
		var tex = load(overlay_path)
		overlay_node = Sprite2D.new()
		overlay_node.texture = tex
		overlay_node.position = $EggSpawnPoint.position + Vector2(0, 30)
		overlay_node.scale = Vector2(0.1, 0.1)
		overlay_node.z_index = 100
		overlay_node.z_as_relative = false
		add_child(overlay_node)
	else:
		push_warning("⚠️ Overlay not found for: " + penguin_type)

func show_panel_message(msg: String):
	if has_node("/root/Main/UI/InfoLabel"):
		var label = get_node("/root/Main/UI/InfoLabel")
		label.text = msg
		label.visible = true
		await get_tree().create_timer(2).timeout
		label.visible = false

func get_upgrade_cost() -> int:
	return int(BASE_UPGRADE_COST + level * level * UPGRADE_MULTIPLIER)

func upgrade():
	if level >= MAX_LEVEL:
		show_panel_message("Max level reached!")
		return

	var cost = get_upgrade_cost()
	if not GameState.spend_coins(cost):
		show_panel_message("Not enough coins to upgrade.")
		return

	level += 1

	for penguin in GameState.owned_penguins:
		if typeof(penguin) == TYPE_DICTIONARY and penguin.get("id", "") == egg_id:
			penguin["level"] = level
			break

	GameState.save_to_db()
	show_panel_message("Penguin leveled up to %d!" % level)

	var sound = get_tree().root.get_node_or_null("Main/UpgradeSound")
	if sound:
		sound.play()

func update_progress(ratio: float):
	if progress_bar:
		progress_bar.value = clamp(ratio, 0.0, 1.0)
		progress_bar.visible = ratio < 1.0
