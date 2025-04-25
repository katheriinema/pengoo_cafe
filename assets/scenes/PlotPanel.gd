# res://assets/scripts/PlotPanel.gd
extends Panel

@export var icon_folder : String      = "res://assets/art/icons/"  # <-- where your .pngs live

@onready var name_input   = $NameInput
@onready var plot_image   = $PlotImage
@onready var description  = $Description
@onready var action_btn   = $ActionButton
@onready var skill_icon   = $SkillIcon
@onready var upgrade_button = $UpgradeButton


var current_plot

func _ready():
	name_input.connect("text_submitted", Callable(self, "_on_name_submitted"))
	hide()

func show_for_plot(plot):
	current_plot = plot
	plot_image.texture = plot.get_display_texture()

	if plot.is_egg():
		description.text = plot.get_description()
	else:
		description.text = plot.get_panel_description()

	# Clear old action_btn connections
	for cb in [Callable(self, "_on_feed"), Callable(self, "_on_sell")]:
		if action_btn.is_connected("pressed", cb):
			action_btn.disconnect("pressed", cb)

	if plot.is_egg():
		name_input.visible = false
		action_btn.visible = true
		action_btn.text = "Feed me"
		action_btn.disabled = false
		action_btn.connect("pressed", Callable(self, "_on_feed"))
		skill_icon.visible = false
	else:
		name_input.visible = true
		name_input.text = plot.penguin_name
		name_input.placeholder_text = "Enter name for your %s penguin" % plot.penguin_type
		name_input.grab_focus()

		action_btn.visible = true
		action_btn.text = "Sell"
		action_btn.disabled = plot.is_starter
		if not action_btn.disabled:
			action_btn.connect("pressed", Callable(self, "_on_sell"))

		# 🐧 Show upgrade even for starter, and when maxed
		upgrade_button.visible = plot.is_hatched

		if plot.level >= plot.MAX_LEVEL:
			upgrade_button.text = "Max Level"
			upgrade_button.disabled = true
		else:
			upgrade_button.text = "Level Up ($%d)" % plot.get_upgrade_cost()
			upgrade_button.disabled = false

		# Safe connect
		if upgrade_button.pressed.is_connected(Callable(self, "_on_upgrade_pressed")):
			upgrade_button.pressed.disconnect(Callable(self, "_on_upgrade_pressed"))

		upgrade_button.pressed.connect(Callable(self, "_on_upgrade_pressed"))

	show()


func _on_feed():
	current_plot.feed()
	show_for_plot(current_plot)

func _on_name_submitted(text:String):
	if text.strip_edges() != "":
		current_plot.set_penguin_name(text)
		show_for_plot(current_plot)

func _on_sell():
	current_plot.sell()
	hide()

func _on_upgrade_pressed():
	if current_plot:
		current_plot.upgrade()
		show_for_plot(current_plot)
