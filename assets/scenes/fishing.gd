extends Node2D

@onready var power_meter = $UI/PowerMeter
var increasing = true
var fishing_enabled = true
var regen_interval := 60  # seconds
var seconds_until_next_energy := regen_interval

func _process(delta):
	if !fishing_enabled:
		return

	if increasing:
		power_meter.value += 100 * delta
		if power_meter.value >= 100:
			increasing = false
	else:
		power_meter.value -= 100 * delta
		if power_meter.value <= 0:
			increasing = true

func _input(event):
	if event.is_action_pressed("ui_accept") and fishing_enabled:
		check_catch()

@onready var fish_scene = preload("res://assets/scenes/Fish.tscn")

func spawn_fish():
	var fish = fish_scene.instantiate()
	var center = Vector2(350, 300)  # Your central target spawn point
	var x_offset = randf_range(-50, 50)  # Small horizontal variation
	var y_offset = randf_range(-25, 25)  # Small vertical variation

	fish.position = center + Vector2(x_offset, y_offset)
	add_child(fish)

@onready var fish_counter_label = $UI/FishCounter

func update_fish_count():
	GameState.add_fish()
	fish_counter_label.text = "Fish: %d" % GameState.fish_inventory

func check_catch():
	var current = power_meter.value
	fishing_enabled = false

	var feedback = ""
	if current > 48 and current < 52:
		feedback = "Perfect!"
		spawn_fish()
		GameState.add_fish()
	elif current > 40 and current < 60:
		feedback = "Good!"
		spawn_fish()
		GameState.add_fish()
	else:
		feedback = "Miss!"

	show_feedback(feedback)

	await get_tree().create_timer(1.5).timeout
	fishing_enabled = true

func _on_fish_button_pressed() -> void:
	if not fishing_enabled:
		return
	if not GameState.use_energy(1):
		show_feedback("Too tired!")
		return
	check_catch()

@onready var feedback_label = $UI/FeedbackLabel

func show_feedback(text: String):
	feedback_label.text = text
	feedback_label.modulate.a = 1.0  # reset opacity

	# Fade out smoothly
	feedback_label.create_tween().tween_property(
		feedback_label, "modulate:a", 0.0, 1.2
	)


@onready var energy_label := $UI/EnergyLabel

func _update_energy_label(current: int, max: int):
	energy_label.text = "Energy: %d / %d" % [current, max]



@onready var energy_timer_label := $UI/EnergyTimerLabel

func _on_countdown_timer_timeout() -> void:
	seconds_until_next_energy -= 1
	if seconds_until_next_energy <= 0:
		GameState.restore_energy(1)
		seconds_until_next_energy = regen_interval
	update_timer_label()

func update_timer_label():
	energy_timer_label.text = "Next Energy In: %ds" % seconds_until_next_energy

func _ready():
	update_timer_label()
	_update_energy_label(GameState.current_energy, GameState.max_energy)
	fish_counter_label.text = "Fish: %d" % GameState.fish_inventory
	GameState.connect("fish_changed", Callable(self, "_update_fish_ui"))
	GameState.connect("energy_changed", Callable(self, "_update_energy_label"))

func _update_fish_ui(amount: int):
	fish_counter_label.text = "Fish: %d" % amount

func _on_exit_button_pressed() -> void:
	GameState.save_to_db()
	get_tree().change_scene_to_file("res://assets/scenes/Main.tscn")
