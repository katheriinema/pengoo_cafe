extends Node2D

@onready var power_meter = $UI/PowerMeter
@onready var click_sound = $ClickSound
@onready var success_sound = $SuccessSound
@onready var success_box = $UI/SuccessBox
@onready var fish_counter_label = $UI/FishCounter
@onready var feedback_label = $UI/FeedbackLabel
@onready var energy_label = $UI/EnergyLabel
@onready var energy_timer_label = $UI/EnergyTimerLabel

@onready var fish_scene = preload("res://assets/scenes/Fish.tscn")

var increasing = true
var fishing_enabled = true
var regen_interval := 60  # seconds
var seconds_until_next_energy := regen_interval

func _ready():
	MusicManager.pause_music()
	update_timer_label()
	_update_energy_label(GameState.current_energy, GameState.max_energy)
	fish_counter_label.text = "Fish: %d" % GameState.fish_inventory

	GameState.connect("fish_changed", Callable(self, "_update_fish_ui"))
	GameState.connect("energy_changed", Callable(self, "_update_energy_label"))

	setup_success_box()

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

func _on_fish_button_pressed():
	if not fishing_enabled:
		return
	if not GameState.use_energy(1):
		show_feedback("Too tired!")
		return
	check_catch()

func check_catch():
	var current = power_meter.value
	fishing_enabled = false

	var feedback = ""
	if current > 45 and current < 55:
		feedback = "Good!"
		spawn_fish()
		GameState.add_fish()
		if success_sound:
			success_sound.play()
	else:
		feedback = "Miss!"
		if click_sound:
			click_sound.play()

	show_feedback(feedback)

	await get_tree().create_timer(1.5).timeout
	fishing_enabled = true

func spawn_fish():
	var fish = fish_scene.instantiate()
	var center = Vector2(350, 300)
	var x_offset = randf_range(-50, 50)
	var y_offset = randf_range(-25, 25)
	fish.position = center + Vector2(x_offset, y_offset)
	add_child(fish)

func show_feedback(text: String):
	feedback_label.text = text
	feedback_label.modulate.a = 1.0
	feedback_label.create_tween().tween_property(
		feedback_label, "modulate:a", 0.0, 1.2
	)

func _update_fish_ui(amount: int):
	fish_counter_label.text = "Fish: %d" % amount

func _update_energy_label(current: int, max: int):
	energy_label.text = "Energy: %d / %d" % [current, max]

func _on_countdown_timer_timeout():
	seconds_until_next_energy -= 1
	if seconds_until_next_energy <= 0:
		GameState.restore_energy(1)
		seconds_until_next_energy = regen_interval
	update_timer_label()

func update_timer_label():
	energy_timer_label.text = "Next Energy In: %ds" % seconds_until_next_energy

func setup_success_box():
	var bar_width = power_meter.size.x
	var bar_height = power_meter.size.y

	var low = 45.0 / 100.0
	var high = 55.0 / 100.0

	success_box.position.x = power_meter.position.x + (bar_width * low)
	success_box.position.y = power_meter.position.y
	success_box.size.x = bar_width * (high - low)
	success_box.size.y = bar_height

func _on_exit_button_pressed():
	GameState.save_to_db()
	MusicManager.resume_music()
	if click_sound:
		click_sound.play()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://assets/scenes/Main.tscn")
