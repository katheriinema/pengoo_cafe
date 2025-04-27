extends Panel

@export var icon_folder : String = "res://assets/art/icons/"

@onready var name_input     = $NameInput
@onready var plot_image     = $PlotImage
@onready var description    = $Description
@onready var action_btn     = $ActionButton
@onready var skill_icon     = $SkillIcon
@onready var upgrade_button = $UpgradeButton

var current_plot

func _ready():
	name_input.connect("text_submitted", Callable(self, "_on_name_submitted"))
	hide()

func show_for_plot(plot):
	current_plot = plot
	plot_image.texture = plot.get_display_texture()
	description.text = plot.get_description() if plot.is_egg() else plot.get_panel_description()

	# 🔊 Play UI click sound
	var sound = get_tree().root.get_node_or_null("Main/ClickSound")
	if sound:
		sound.play()

	# Clear old signal connections
	if action_btn.is_connected("pressed", Callable(self, "_on_feed")):
		action_btn.disconnect("pressed", Callable(self, "_on_feed"))
	if action_btn.is_connected("pressed", Callable(self, "_on_sell")):
		action_btn.disconnect("pressed", Callable(self, "_on_sell"))
	if upgrade_button.pressed.is_connected(Callable(self, "_on_upgrade_pressed")):
		upgrade_button.pressed.disconnect(Callable(self, "_on_upgrade_pressed"))

	if plot.is_egg():
		# Feeding UI
		name_input.visible = false
		action_btn.visible = true
		action_btn.text = "Feed me"
		action_btn.disabled = false
		action_btn.connect("pressed", Callable(self, "_on_feed"))
		skill_icon.visible = false
		upgrade_button.visible = false
	else:
		# Penguin UI
		name_input.visible = true
		name_input.text = plot.penguin_name
		name_input.placeholder_text = "Enter name for your %s penguin" % plot.penguin_type
		name_input.grab_focus()

		action_btn.visible = true
		action_btn.text = "Sell"
		action_btn.disabled = plot.is_starter
		if not plot.is_starter:
			action_btn.connect("pressed", Callable(self, "_on_sell"))

		# 🧠 Skill icon logic
		var skill_path = "res://assets/art/skill_icon/%s_skill.png" % plot.penguin_type
		if ResourceLoader.exists(skill_path):
			skill_icon.texture = load(skill_path)
			skill_icon.visible = true
		else:
			skill_icon.visible = false
			push_warning("Skill icon not found: " + skill_path)

		# Upgrade button
		upgrade_button.visible = true
		if plot.level >= plot.MAX_LEVEL:
			upgrade_button.text = "Max Level"
			upgrade_button.disabled = true
		else:
			upgrade_button.text = "Level Up ($%d)" % plot.get_upgrade_cost()
			upgrade_button.disabled = false
			upgrade_button.pressed.connect(Callable(self, "_on_upgrade_pressed"))


	show()

func _on_feed():
	current_plot.feed()
	show_for_plot(current_plot)

func _on_name_submitted(text: String):
	if text.strip_edges() != "":
		current_plot.set_penguin_name(text)
		show_for_plot(current_plot)

func _on_sell():
	current_plot.sell()
	hide()

func _on_upgrade_pressed():
	current_plot.upgrade()
	show_for_plot(current_plot)
