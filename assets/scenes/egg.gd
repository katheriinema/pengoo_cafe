extends Node2D

@onready var sprite := $Sprite2D

@export var rarity: String = "common"

func _ready():
	var egg_path = "res://assets/art/eggs/%s_egg.png" % rarity
	if ResourceLoader.exists(egg_path):
		sprite.texture = load(egg_path)
		sprite.scale = Vector2(0.15, 0.15)  # ✅ scale it down
	else:
		push_warning("Egg image not found for rarity: " + rarity)
