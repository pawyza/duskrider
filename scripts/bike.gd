extends VehicleBody3D

@export var max_steer : float = 0.5
@export var engine_power : float = 4000.0
@export var breaking_power : float = 25.0

@onready var camera_pivot = $CameraPivot
@onready var camera_3d = $CameraPivot/Camera3D

var player 
var camera_origin

var has_started = false
var is_on_ground = false

func _ready():
	player = get_parent().get_node("Player")
	camera_origin = $CameraPivot/Camera3D.transform

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if $GetOffBike.is_stopped():
		if camera_3d.current:
			$SunRayCast.enabled = true
			steering = move_toward(steering, Input.get_axis("ui_left", "ui_right") * max_steer, delta * 2.5)
			if !has_started and linear_velocity.length() > 4.0:
				$AccellerationAudio.play()
				$AnimationPlayer.play("RattleStart")
				has_started = true
			var speed_axis = Input.get_axis("ui_down", "ui_up")
			if speed_axis > 0:
				engine_force = speed_axis * engine_power * remap(linear_velocity.length(),0,60,1,0)
			else:
				engine_force = speed_axis * engine_power / 5 * remap(linear_velocity.length(),0,40,1,0)
				
			$RattleAudio.stream_paused = false
			$MainHumAudio.stream_paused = false
			$MainHumAudio.volume_db = remap(linear_velocity.length(),20,60,-10,20)
			$MainHumAudio.pitch_scale = remap(linear_velocity.length(),20,60,0.7,1.5)

			if Input.is_action_pressed("bike_break"):
				brake = breaking_power
			else:
				brake = 0
			check_if_in_sun()
			
			$GetOffPoint.global_position.y = global_position.y
			$GetOffPoint.global_rotation.x = 0
			$GetOffPoint.global_rotation.z = 0
			$GetOffPoint.global_rotation.y = $GetOffPoint.global_position.angle_to(global_position)+PI
		
			if Input.is_action_just_pressed("enter_bike"):
				player.global_transform = $GetOffPoint.global_transform
				player.get_node("CollisionShape3D").disabled = false
				if has_started:
					$AnimationPlayer.play("RattleStop")
					$AccellerationAudio.stop()
					$StopExitAudio.play()
				has_started = false
				$GetOffBike.start()
				
		else:
			brake = breaking_power
			$MainHumAudio.stream_paused = true
			$RattleAudio.stream_paused = true
			$SunRayCast.enabled = false
			if get_contact_count() > 0:
				is_on_ground = true
			else:
				is_on_ground = false

		if camera_3d.current and linear_velocity.length() < 10:
			$CanvasLayer.show()
		else:
			$CanvasLayer.hide()
			

		camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta * 30.0)
		camera_pivot.transform = camera_pivot.transform.interpolate_with(transform, delta * 12.0)

	if !$GetOffBike.is_stopped():
		$CameraPivot/Camera3D.global_transform = $CameraPivot/Camera3D.global_transform.interpolate_with(player.get_node("Head").global_transform, delta * 10.0)


func _integrate_forces(state):
	angular_velocity.y = clamp(angular_velocity.y, -2.0, 2.0)

func check_current_camera():
	return camera_3d.current
	
func set_current_camera():
	camera_3d.make_current()
	$CameraPivot/Camera3D/AudioListener3D.make_current()

func _on_get_off_bike_timeout():
	EventManager.change_camera_to_player.emit()
	$CameraPivot/Camera3D.transform = camera_origin

func check_if_in_sun():
	$SunRayCast.global_rotation = get_parent().get_node("Sun").global_rotation
	if !$SunRayCast.is_colliding():
		get_parent().overheating = true
	else:
		get_parent().overheating = false

func _on_rattle_audio_finished():
	$RattleAudio.play()

func _on_main_hum_audio_finished():
	$MainHumAudio.play()

func pick_up():
	global_position.y = 2
	global_rotation.x = 0
	global_rotation.z = 0
	is_on_ground = false
