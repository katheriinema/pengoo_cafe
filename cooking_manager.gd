extends Node

const COOK_TIMES = {
	"taiyaki":   20,
	"redbean":   30,
	"chocolate": 40,
	"cream":     30,
	"matcha":    50
}

const TAIYAKI_PRICES = {
	"plain":     10,
	"redbean":   50,
	"chocolate": 50,
	"cream":     30,
	"matcha":    100
}

var penguin_timers := {}
var ingredient_queue: Array[Dictionary] = []
var taiyaki_timer: Timer
var taiyaki_plot_ref: Node = null

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

	if penguin_type == "taiyaki" and taiyaki_plot_ref == null:
		taiyaki_plot_ref = plot
		if taiyaki_timer.is_stopped():
			_try_start_taiyaki()
		return
	else:
		var timer = Timer.new()
		timer.one_shot = true
		var duration = COOK_TIMES.get(penguin_type, 20)
		timer.wait_time = duration
		add_child(timer)
		penguin_timers[plot.egg_id] = { "timer": timer, "duration": duration, "plot": plot }
		timer.connect("timeout", Callable(self, "_on_ingredient_done").bind(plot.egg_id))
		timer.start()
		print("⏱️ Started timer for:", penguin_type, "ID:", plot.egg_id)

func _on_ingredient_done(egg_id: String):
	print("✅ Ingredient done from:", egg_id)

	for entry in GameState.owned_penguins:
		if typeof(entry) == TYPE_DICTIONARY and entry.get("id") == egg_id:
			var type = entry.get("type", "")
			var level = entry.get("level", 1)
			ingredient_queue.append({ "type": type, "level": level })
			print("🍫 Queued ingredient:", type, "at level", level)
			break

	# Restart the ingredient penguin's timer
	if penguin_timers.has(egg_id):
		var info = penguin_timers[egg_id]
		if typeof(info) == TYPE_DICTIONARY and info.has("timer"):
			var timer = info["timer"]
			if timer:
				timer.start()

	# Now start taiyaki cooking based on updated queue
	_try_start_taiyaki()


func _try_start_taiyaki():
	print("🔥 Try start taiyaki. Queue:", ingredient_queue)

	if ingredient_queue.is_empty():
		print("🛑 No ingredients in queue. Waiting...")
		return

	if not ingredient_queue.is_empty() and taiyaki_timer.is_stopped():
		var base_time = COOK_TIMES["taiyaki"]
		var taiyaki_level = 1

		for p in GameState.owned_penguins:
			if typeof(p) == TYPE_DICTIONARY and p.get("type", "") == "taiyaki":
				taiyaki_level = p.get("level", 1)
				break

		var speed_bonus = 1.0 - (taiyaki_level * 0.01)
		var adjusted_time = base_time * clamp(speed_bonus, 0.05, 1.0)

		# ✅ Set meta BEFORE starting the timer to ensure correct ratio on frame 1
		if taiyaki_plot_ref:
			taiyaki_plot_ref.set_meta("taiyaki_duration", adjusted_time)

		taiyaki_timer.wait_time = adjusted_time
		taiyaki_timer.start()
		print("🕒 Started taiyaki cooking. Level:", taiyaki_level, "Time:", adjusted_time)




func _on_taiyaki_done():
	if ingredient_queue.is_empty():
		print("❌ Queue was empty on cook completion.")
		return

	var entry = ingredient_queue.pop_front()
	var key = entry["type"]
	var level = entry.get("level", 1)

	var base_price = TAIYAKI_PRICES.get(key, 10)
	var base_bonus = base_price * 0.02 * level
	var tier_bonus = 0.0

	if level >= 90:
		tier_bonus = base_price * 0.5
	elif level >= 60:
		tier_bonus = base_price * 0.25
	elif level >= 30:
		tier_bonus = base_price * 0.1

	var bonus = int(base_bonus + tier_bonus)
	var payout = base_price + bonus

	print("✅ Taiyaki done with:", key, "Level:", level, "→ Payout:", payout)

	_emit_selling_item(key, payout)
	_try_start_taiyaki()


func _emit_selling_item(ingredient_type: String, payout: int, persist := true):
	print("💸 Creating SellingItem for:", ingredient_type, "->", payout)

	if persist:
		GameState.for_sale_items.append({ "type": ingredient_type, "payout": payout })
		GameState.save_to_db()

	var list = get_tree().root.get_node_or_null("Main/WorldLayer/SellWindow/ItemList")
	if not list:
		push_error("❌ SellWindow/ItemList not found!")
		return

	var row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_STOP

	var icon = TextureRect.new()
	icon.texture = load("res://assets/art/product_icon/%s_icon.png" % ingredient_type)
	icon.custom_minimum_size = Vector2(64, 64)
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	var label = Label.new()
	label.text = "+$%s" % payout
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

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
			# 🔊 Play sound!
			var sell_sound = get_tree().root.get_node("Main/SellSound")
			if sell_sound:
				sell_sound.play()
	)

	list.add_child(row)

func _process(_delta):
	for id in penguin_timers.keys():
		var info = penguin_timers[id]
		if typeof(info) == TYPE_DICTIONARY:
			var t: Timer = info.get("timer")
			var d: float = info.get("duration", 1.0)
			var p = info.get("plot")
			if t and p and t.time_left > 0:
				var ratio = 1.0 - (t.time_left / d)
				p.update_progress(ratio)

	# ✅ Update taiyaki progress only once per frame, using saved duration
	if taiyaki_plot_ref and taiyaki_timer and taiyaki_timer.time_left > 0:
		var adjusted_time = taiyaki_plot_ref.get_meta("taiyaki_duration", COOK_TIMES["taiyaki"])
		var ratio = 1.0 - (taiyaki_timer.time_left / adjusted_time)
		taiyaki_plot_ref.update_progress(ratio)



	# Update progress for taiyaki penguin
	if taiyaki_plot_ref and taiyaki_timer and taiyaki_timer.time_left > 0:
		var base_time = COOK_TIMES["taiyaki"]
		var taiyaki_level = taiyaki_plot_ref.level
		var speed_bonus = 1.0 - (taiyaki_level * 0.01)
		var adjusted_time = base_time * clamp(speed_bonus, 0.05, 1.0)
		var ratio = 1.0 - (taiyaki_timer.time_left / adjusted_time)
		taiyaki_plot_ref.update_progress(ratio)
