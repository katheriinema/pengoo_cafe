extends Node2D

@onready var common_button = $EggContainer/EggCommon/BuyButtonCommon
@onready var rare_button   = $EggContainer/EggRare/BuyButtonRare
@onready var epic_button   = $EggContainer/EggEpic/BuyButtonEpic

@onready var confirmation  = $ConfirmationPopup
@onready var limit_popup    = $LimitPopup
@onready var success_label  = $SuccessLabel
@onready var money_label    = $MoneyLabel

var selected_egg_type = ""
var prices = {"common":10, "rare":50, "epic":200}

const RARITY_TO_TYPES = {
	"common": ["taiyaki", "cream"],
	"rare": ["redbean", "chocolate"],
	"epic": ["matcha"]
}


func _ready():
	randomize()
	money_label.text = "💰 $%d" % GameState.coins
	GameState.connect("coins_changed", Callable(self, "_update_money_label"))

func _update_money_label(new_amount:int):
	money_label.text = "💰 $%d" % new_amount

func _on_buy_button_common_pressed():
	_on_buy_button_pressed("common")

func _on_buy_button_rare_pressed():
	_on_buy_button_pressed("rare")

func _on_buy_button_epic_pressed():
	_on_buy_button_pressed("epic")

func _on_buy_button_pressed(egg_type:String):
	var total = GameState.owned_eggs.size() + GameState.owned_penguins.size()
	if total >= 4:
		limit_popup.dialog_text = "Inventory full! Max 4 total."
		limit_popup.popup_centered()
		return

	selected_egg_type = egg_type
	confirmation.dialog_text = "Buy a %s egg for $%d?" % [egg_type.capitalize(), prices[egg_type]]
	confirmation.popup_centered()

func _on_confirmation_popup_confirmed():
	var total = GameState.owned_eggs.size() + GameState.owned_penguins.size()
	if total >= 4:
		limit_popup.dialog_text = "Cannot buy more—inventory is full."
		limit_popup.popup_centered()
		return

	var cost = prices[selected_egg_type]
	if not GameState.spend_coins(cost):
		show_success_message("Not enough money!")
		return

	# ─── Get next available plot index (0–3) ───
	# Build list of occupied plot indices from both eggs and penguins
	var taken = GameState.get_used_plot_indices()

	var next_index = 0
	while taken.has(next_index) and next_index < 4:
		next_index += 1
	print("🐣 Eggs:", GameState.owned_eggs)
	print("🐧 Penguins:", GameState.owned_penguins)
	print("📦 Total count:", GameState.owned_eggs.size() + GameState.owned_penguins.size())

	if next_index >= 4:
		limit_popup.dialog_text = "All 4 plots are full!"
		limit_popup.popup_centered()
		return

	# ─── Create egg with plot_index ───
	var egg_id = "%s_%d" % [selected_egg_type, Time.get_unix_time_from_system()]
	var possible_types = RARITY_TO_TYPES.get(selected_egg_type, [])
	var chosen_type = possible_types[randi() % possible_types.size()]

	var egg_entry = {
		"id": egg_id,
		"rarity": selected_egg_type,
		"type": chosen_type,
		"plot_index": next_index
	}

	GameState.owned_eggs.append(egg_entry)
	GameState.save_to_db()

	show_success_message("You bought a %s egg!" % selected_egg_type.capitalize())


func show_success_message(msg:String):
	success_label.text = msg
	success_label.visible = true
	await get_tree().create_timer(2.0).timeout
	success_label.visible = false

func _on_exit_button_pressed():
	get_tree().change_scene_to_file("res://assets/scenes/Main.tscn")
