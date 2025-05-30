extends Control

signal cutscene_finished

@onready var panel = $PanelDisplay
@onready var caption_bg = $CaptionBg
@onready var caption = $Caption

var panels = []
var captions = []
var idx = -1
var tweening = false

const FADE_TIME = 0.5
const CAPTION_DELAY = 0.5
const CAPTION_FADE = 0.3

func _ready():
	MusicManager.pause_music()

	panels = [
		preload("res://assets/art/cutscenes/first.png"),
		preload("res://assets/art/cutscenes/second.png"),
		preload("res://assets/art/cutscenes/third.png"),
		preload("res://assets/art/cutscenes/fourth.png"),
		preload("res://assets/art/cutscenes/fifth.png"),
		preload("res://assets/art/cutscenes/sixth.png"),
	]
	captions = [
		"Once a bustling penguin colony thrived on the ice…",
		"But the ice cracked and drifted away under a warming sky…",
		"One little penguin found themselves alone, floating…",
		"They paddled onward, hoping for a new home…",
		"At last, distant shores appeared through the mist…",
		"And so began the journey of a brand new village."
	]
	_show_next()

func _input(event):
	if not tweening \
	and panel.visible \
	and event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		_fade_out()

func _show_next():
	idx += 1
	if idx >= panels.size():
		_finalize_cutscene()
		return

	panel.texture = panels[idx]
	caption.text = captions[idx]
	panel.visible = true
	caption.visible = true
	caption_bg.visible = true

	panel.modulate.a = 0.0
	caption_bg.modulate.a = 0.0
	caption.modulate.a = 0.0

	tweening = true
	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, FADE_TIME)
	tw.tween_property(caption_bg, "modulate:a", 0.5, FADE_TIME)
	tw.tween_interval(CAPTION_DELAY)
	tw.tween_property(caption, "modulate:a", 1.0, CAPTION_FADE)
	tw.tween_callback(Callable(self, "_on_fade_in_done"))

func _on_fade_in_done():
	tweening = false

func _fade_out():
	tweening = true
	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 0.0, FADE_TIME)
	tw.tween_property(caption_bg, "modulate:a", 0.0, FADE_TIME)
	tw.tween_property(caption, "modulate:a", 0.0, FADE_TIME)
	tw.tween_callback(Callable(self, "_show_next"))

func _on_finish_pressed():
	_finalize_cutscene()

func _finalize_cutscene():
	GameState.has_onboarded = true
	GameState.save_to_db()
	MusicManager.resume_music()
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://assets/scenes/onboarding.tscn")
