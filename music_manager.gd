# MusicManager.gd
extends Node

@onready var music_player = $MusicPlayer
var current_track: AudioStream = null  # ✅ Store the current track

func _ready():
	# Ensure it persists and starts
	process_mode = Node.PROCESS_MODE_ALWAYS
	if music_player.stream:
		current_track = music_player.stream
		music_player.play()

func play_music(new_stream: AudioStream):
	if music_player.stream != new_stream:
		current_track = new_stream
		music_player.stream = new_stream
		music_player.play()
		print("🎶 Now playing:", new_stream.resource_path)

func stop_music():
	if music_player and music_player.playing:
		music_player.stop()
		print("🛑 Music stopped")

func resume_music():
	if music_player and current_track:
		music_player.stream = current_track
		music_player.play()
		print("▶️ Music resumed")

func pause_music():
	if music_player and music_player.playing:
		music_player.stream_paused = true
		print("⏸️ Music paused")
