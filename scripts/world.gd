extends Node3D

const MENU_SCENE_PATH : String = "res://scenes/menu.tscn"

var overheating : bool = false
var overheated : int = 0
@export var overheated_limit : int = 100

func _ready():
	$AudioTranscript/StartDialogAnimationPlayer.play("StartingDialog")
	$Effects/Gradient.material.set_shader_parameter("effect_filling", 0)
	EventManager.change_camera_to_bike.connect(change_camera_to_bike)
	EventManager.change_camera_to_player.connect(change_camera_to_player)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("close"):
		get_tree().change_scene_to_file(MENU_SCENE_PATH)
	
func change_camera_to_bike():
	$Bike.set_current_camera()
	
func change_camera_to_player():
	$Player.set_current_camera()

var dying = false

func _on_overheating_check_timer_timeout():
	if overheating and overheated <= overheated_limit:
		overheated += 1
	elif !overheating and overheated >= 0:
		overheated -= 2
	
	if overheated >= 35:
		$Effects/Gradient.material.set_shader_parameter("effect_filling",remap(overheated,35,overheated_limit,0,0.75))
		
	if overheated > 10:
		$DeathSizzle.stream_paused = false
		$DeathSizzle.volume_db = remap(overheated,10,overheated_limit,-20,15)
	else:
		$DeathSizzle.stream_paused = true
	
	if overheated >= overheated_limit and !dying:
		dying = true
		EventManager.emit_signal("death")
		$AudioTranscript/StartDialogAnimationPlayer.play("DeathDialog")

func _on_sandstorm_body_entered(body):
	if body.name == "Player" and !dying:
		dying = true
		EventManager.emit_signal("death")
		$AudioTranscript/StartDialogAnimationPlayer.play("DeathDialog")

func _on_death_sound_finished():
	get_tree().reload_current_scene()

func _on_day_ambient_finished():
	$DayAmbient.play()

func _on_night_ambient_finished():
	$NightAmbient.play()

func _on_death_sizzle_finished():
	$DeathSizzle.play()

func _on_area_3d_body_entered(body):
	EventManager.emit_signal("win")
	$AudioTranscript/StartDialogAnimationPlayer.play("FinishDialog")
