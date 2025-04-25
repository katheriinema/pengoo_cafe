# res://assets/scripts/PlotPanel.gd
extends Panel

@export var icon_folder : String      = "res://assets/art/icons/"  # <-- where your .pngs live

@onready var name_input   = $NameInput
@onready var plot_image   = $PlotImage
@onready var description  = $Description
@onready var action_btn   = $ActionButton
@onready var skill_icon   = $SkillIcon

var current_plot

func _ready():
	name_input.connect("text_submitted", Callable(self, "_on_name_submitted"))
	hide()

func show_for_plot(plot):
	current_plot = plot
	plot_image.texture = plot.get_display_texture()

	# Description: egg vs. penguin
	if plot.is_egg():
		description.text = plot.get_description()
	else:
		description.text = plot.get_panel_description()

	# Clear previous button handlers
	for cb in [Callable(self, "_on_feed"), Callable(self, "_on_sell")]:
		if action_btn.is_connected("pressed", cb):
			action_btn.disconnect("pressed", cb)

	if plot.is_egg():
		# ─── EGG PHASE ───
		name_input.visible  = false
		action_btn.visible  = true
		action_btn.text     = "Feed me"
		action_btn.disabled = false
		action_btn.connect("pressed", Callable(self, "_on_feed"))
		skill_icon.visible  = false
	else:
		# ─── HATCHED PHASE ───
		name_input.visible          = true
		name_input.text             = plot.penguin_name
		name_input.placeholder_text = "Enter name for your %s penguin" % plot.penguin_type
		name_input.grab_focus()

		action_btn.visible = true
		action_btn.text    = "Sell"

		# ——— Load the icon from disk ———
		var icon_path = "res://assets/art/icons/%s_icon.png" % plot.penguin_type
		if ResourceLoader.exists(icon_path):
			skill_icon.texture = load(icon_path)
			skill_icon.visible = true
		else:
			skill_icon.visible = false

		action_btn.disabled = plot.is_starter
		if not action_btn.disabled:
			action_btn.connect("pressed", Callable(self, "_on_sell"))

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
