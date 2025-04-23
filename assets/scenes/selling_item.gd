extends Button

var payout: int = 0

func setup(ingredient_type: String, amount: int):
	text = "%s Taiyaki\n$%d\n(Click)" % [ingredient_type.capitalize(), amount]
	payout = amount

func _ready():
	pressed.connect(Callable(self, "_on_pressed"))

func _on_pressed():
	GameState.add_coins(payout)
	queue_free()
