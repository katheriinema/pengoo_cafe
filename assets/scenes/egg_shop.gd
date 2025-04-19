extends Node2D

var selected_egg_type = ""
var prices = {"common": 10, "rare": 50, "epic": 200}

func _ready():
	$MoneyLabel.text = "💰 $" + str(GameState.coins)
	GameState.connect("coins_changed", Callable(self, "_update_money_label"))

func _update_money_label(new_amount: int):
	$MoneyLabel.text = "💰 $" + str(new_amount)


func _on_buy_button_common_pressed():
	_on_buy_button_pressed("common")

func _on_buy_button_rare_pressed():
	_on_buy_button_pressed("rare")

func _on_buy_button_epic_pressed():
	_on_buy_button_pressed("epic")

# Shared function that updates the popup dialog
func _on_buy_button_pressed(egg_type: String):
	selected_egg_type = egg_type
	$ConfirmationPopup.dialog_text = "Do you want to buy a %s egg for $%d?" % [egg_type.capitalize(), prices[egg_type]]
	$ConfirmationPopup.popup_centered()

func _on_confirmation_popup_confirmed() -> void:
	var cost = prices[selected_egg_type]
	if GameState.spend_coins(cost):
		# Record the egg in the player’s inventory
		GameState.owned_eggs.append(selected_egg_type)
		GameState.save_to_db()

		var msg = "You bought a %s egg!" % selected_egg_type.capitalize()
		show_success_message(msg)
	else:
		show_success_message("Not enough money!")

func show_success_message(msg: String):
	$SuccessLabel.text = msg
	$SuccessLabel.visible = true
	await get_tree().create_timer(2.0).timeout
	$SuccessLabel.visible = false


func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://assets/scenes/Main.tscn")
