extends CharacterBody3D

const MENU_SCENE_PATH : String = "res://scenes/menu.tscn"

var SPEED = 20.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var mouseSensivity = 1200/4
var mouse_relative_x = 0
var mouse_relative_y = 0

var head_origin

@export var PLYR_FS_LIST : Array[Resource] = [
	preload("res://audio/PLYR_FS_01.wav"),
	preload("res://audio/PLYR_FS_02.wav"),
	preload("res://audio/PLYR_FS_03.wav"),
	preload("res://audio/PLYR_FS_04.wav"),
	preload("res://audio/PLYR_FS_05.wav"),
	preload("res://audio/PLYR_FS_06.wav"),
	preload("res://audio/PLYR_FS_07.wav"),
	preload("res://audio/PLYR_FS_08.wav"),
	preload("res://audio/PLYR_FS_09.wav"),
	preload("res://audio/PLYR_FS_10.wav"),
	preload("res://audio/PLYR_FS_11.wav"),
	preload("res://audio/PLYR_FS_12.wav"),
	preload("res://audio/PLYR_FS_13.wav"),
	preload("res://audio/PLYR_FS_14.wav"),
]

var bike_idx
var ambinet_idx
var initial_volume_bike
var initial_volume_ambient

@export var volume_change = 0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	head_origin = $Head.transform
	EventManager.death.connect(dying)
	EventManager.win.connect(win)
	bike_idx = AudioServer.get_bus_index("Bike")
	initial_volume_bike = AudioServer.get_bus_volume_db(bike_idx)
	ambinet_idx = AudioServer.get_bus_index("Ambient")
	initial_volume_ambient = AudioServer.get_bus_volume_db(ambinet_idx)

func _physics_process(delta):
	if $GetOnBike.is_stopped():
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= 1.2 * gravity * delta

		if $Head/Camera3D.current:
			$Head/SunRayCast.enabled = true

			# Get the input direction and hanPLYRe the movement/deceleration.
			# As good practice, you should replace UI actions with custom gameplay actions.
			var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
			var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			if direction:
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
				play_step()
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				velocity.z = move_toward(velocity.z, 0, SPEED)
			check_if_in_sun()
		else:
			$Head/SunRayCast.enabled = false

		move_and_slide()
	
	if $Head/Camera3D.current and $Head/InteractRayCast.is_colliding() and $Head/InteractRayCast.get_collider().name == "Bike":
		var bike = $Head/InteractRayCast.get_collider()
		if bike.is_on_ground:
			$CanvasLayer/MarginContainer/GetOn.hide()
			$CanvasLayer/MarginContainer/PickUp.show()
			if Input.is_action_just_pressed("enter_bike"):
				bike.pick_up()
		else:
			$CanvasLayer/MarginContainer/PickUp.hide()
			$CanvasLayer/MarginContainer/GetOn.show()
			if Input.is_action_just_pressed("enter_bike"):
				$GetOnBike.start()
	else:
		$CanvasLayer/MarginContainer/PickUp.hide()
		$CanvasLayer/MarginContainer/GetOn.hide()
	
	if !$GetOnBike.is_stopped():
		$Head.global_transform = $Head.global_transform.interpolate_with(get_parent().get_node("Bike/CameraPivot/Camera3D").global_transform, delta * 10)
		
	if $AnimationPlayer.is_playing():
		var volume_bike = volume_change + initial_volume_bike
		AudioServer.set_bus_volume_db(bike_idx, volume_bike)
		var volume_ambient = volume_change + initial_volume_ambient
		AudioServer.set_bus_volume_db(ambinet_idx, volume_ambient)


func _input(event):
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x / mouseSensivity
		$Head.rotation.x -= event.relative.y / mouseSensivity
		$Head.rotation.x = clamp($Head.rotation.x, -PI/2, PI/2)
		mouse_relative_x = clamp(event.relative.x, -PI/3, PI/3)
		mouse_relative_y = clamp(event.relative.y, -PI/3, PI/3)

func check_current_camera():
	return $Head/Camera3D.current
	
func set_current_camera():
	$Head/Camera3D.make_current()
	$Head/Camera3D/AudioListener3D.make_current()

func _on_get_on_bike_timeout():
	EventManager.change_camera_to_bike.emit()
	$CollisionShape3D.disabled = true
	$Head.transform = head_origin

func check_if_in_sun():
	$Head/SunRayCast.global_rotation = get_parent().get_node("Sun").global_rotation
	if !$Head/SunRayCast.is_colliding():
		get_parent().overheating = true
	else:
		get_parent().overheating = false

func play_step():
	if $StepTimer.is_stopped():
		$StepTimer.start()
		for audioStreamPlayer in $StepPlayers.get_children():
			if not audioStreamPlayer.playing:
				audioStreamPlayer.stream = PLYR_FS_LIST.pick_random()
				audioStreamPlayer.play()
				break

func dying():
	mouseSensivity *= 4
	SPEED *= 1/4
	$AnimationPlayer.play("death")

func _on_animation_player_animation_finished(anim_name):
	$DeathTimer.start()

func _on_death_timer_timeout():
	AudioServer.set_bus_volume_db(bike_idx, initial_volume_bike)
	AudioServer.set_bus_volume_db(ambinet_idx, initial_volume_ambient)
	get_tree().change_scene_to_file(MENU_SCENE_PATH)

func win():
	$AnimationPlayer.play("win")
