extends Node

const COOK_TIMES = {
	"taiyaki":   5,
	"redbean":   5,
	"chocolate": 5,
	"cream":     5,
	"matcha":    5
}

const TAIYAKI_PRICES = {
	"plain":     10,
	"redbean":   20,
	"chocolate": 20,
	"cream":     20,
	"matcha":    40
}

var penguin_timers := {}
var ingredient_queue: Array[String] = []
var taiyaki_timer: Timer

func _ready():
	taiyaki_timer = Timer.new()
	taiyaki_timer.one_shot = true
	add_child(taiyaki_timer)
	taiyaki_timer.connect("timeout", Callable(self, "_on_taiyaki_done"))

func register_plot(plot):
	if plot.is_egg():
		print("🥚 Skipping egg plot")
		return

	var penguin_type = plot.penguin_type
	print("✅ Registering penguin:", penguin_type, "ID:", plot.egg_id)

	if penguin_type == "taiyaki":
		if taiyaki_timer.is_stopped():
			_try_start_taiyaki()
		return
	else:
		var timer = Timer.new()
		timer.one_shot = true
		timer.wait_time = COOK_TIMES.get(penguin_type, 20)
		add_child(timer)
		penguin_timers[plot.egg_id] = timer
		timer.connect("timeout", Callable(self, "_on_ingredient_done").bind(plot.egg_id))
		timer.start()
		print("⏱️ Started timer for:", penguin_type, "ID:", plot.egg_id)

func _on_ingredient_done(egg_id: String):
	print("✅ Ingredient done from:", egg_id)
	for entry in GameState.owned_penguins:
		if typeof(entry) == TYPE_DICTIONARY and entry.get("id") == egg_id:
			var type = entry.get("type", "")
			ingredient_queue.append(type)
			print("🍫 Queued ingredient:", type)
			break

	if penguin_timers.has(egg_id):
		penguin_timers[egg_id].start()

	_try_start_taiyaki()
	
func _try_start_taiyaki():
	print("🔥 Try start taiyaki. Queue:", ingredient_queue)

	# Only enqueue plain taiyaki if it's completely idle and nothing is waiting
	if ingredient_queue.is_empty() and taiyaki_timer.is_stopped():
		var has_taiyaki_penguin = false
		for p in GameState.owned_penguins:
			if typeof(p) == TYPE_DICTIONARY and p.get("type", "") == "taiyaki":
				has_taiyaki_penguin = true
				break

		if has_taiyaki_penguin:
			print("🍞 No ingredients. Enqueuing one plain taiyaki")
			ingredient_queue.append("taiyaki")
		else:
			print("❌ No taiyaki penguin found.")
			return

	# Start the timer if it's not running and we now have something to cook
	if not ingredient_queue.is_empty() and taiyaki_timer.is_stopped():
		taiyaki_timer.wait_time = COOK_TIMES["taiyaki"]
		taiyaki_timer.start()
		print("🕒 Started taiyaki cooking")

func _on_taiyaki_done():
	if ingredient_queue.is_empty():
		return

	var ing = ingredient_queue.pop_front()
	var key = ing if ing != "taiyaki" else "plain"
	var payout = TAIYAKI_PRICES.get(key, 10)

	_emit_selling_item(key, payout)
	_try_start_taiyaki()  # Only start another if there’s still ingredient


func _emit_selling_item(ingredient_type: String, payout: int, persist := true):
	print("💸 Creating SellingItem for:", ingredient_type, "->", payout)

	# Add to GameState and persist BEFORE visual
	if persist:
		GameState.for_sale_items.append({
			"type": ingredient_type,
			"payout": payout
		})
		GameState.save_to_db()

	# Create and show in SellWindow
	var list = get_tree().root.get_node_or_null("Main/WorldLayer/SellWindow/ItemList")
	if not list:
		push_error("❌ SellWindow/ItemList not found!")
		return

	var row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_STOP

	var icon = TextureRect.new()
	icon.texture = load("res://assets/art/icons/%s_icon.png" % ingredient_type)
	icon.custom_minimum_size = Vector2(64, 64)
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	var label = Label.new()
	label.text = "+$%s" % payout
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Set font using LabelSettings
	var font_data = load("res://assets/fonts/Sniglet-Regular.ttf")
	var font = FontFile.new()
	font.font_data = font_data

	var settings = LabelSettings.new()
	settings.font = font
	settings.font_size = 24
	settings.font_color = Color(0.7, 0.5, 0.1, 1.0)
	label.label_settings = settings

	row.add_child(icon)
	row.add_child(label)

	row.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("🪙 Sold:", ingredient_type, "for $%d" % payout)
			GameState.add_coins(payout)
			GameState.for_sale_items = GameState.for_sale_items.filter(func(item): return item["type"] != ingredient_type or item["payout"] != payout)
			GameState.save_to_db()
			row.queue_free()
	)

	list.add_child(row)
