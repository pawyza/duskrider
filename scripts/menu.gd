extends Control

const WORLD_SCENE_PATH : String = "res://scenes/world.tscn"

var bus_idx 
const initial_volume = -5.3

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	bus_idx = AudioServer.get_bus_index("Master")
	$MarginContainer/MainMenu/HBoxContainer4/VBoxContainer/SpinBox.value = (AudioServer.get_bus_volume_db(bus_idx) - initial_volume) * 5 + 50
	var volume = ($MarginContainer/MainMenu/HBoxContainer4/VBoxContainer/SpinBox.value - 50)/5 + initial_volume
	AudioServer.set_bus_volume_db(bus_idx, volume)
	$MarginContainer/MainMenu/HBoxContainer6/VBoxContainer/SpinBox.value = 600 - EventManager.mouseSensivity

# Called every frame. 'delta' is the elapsed time since the previous frame. 
func _process(delta):
	if Input.is_action_just_pressed("close"):
		get_tree().quit()	

func _on_play_button_pressed():
	get_tree().change_scene_to_file(WORLD_SCENE_PATH)

func _on_spin_box_value_changed(value):
	var volume = (value - 50)/5 + initial_volume
	AudioServer.set_bus_volume_db(bus_idx, volume)


func _on_day_start_music_finished():
	$DayStartMusic.play()


func _on_dust_ambient_finished():
	$DustAmbient.play()


func _on_spin_box_value_changed_sensivity(value):
	EventManager.mouseSensivity = 600 - value
