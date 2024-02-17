extends Area3D

@export var move_speed = 5.0

func _ready():
	$SandstormVolume.material.set_shader_parameter("box_limit_x", position.x)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var player_distance_x = 0
	if get_parent().get_node("Player/Head/Camera3D").current:
		$AudioStreamPlayer3D.position.z = get_parent().get_node("Player").position.z
		player_distance_x =  get_parent().get_node("Player").position.x
	else:
		$AudioStreamPlayer3D.position.z = get_parent().get_node("Bike").position.z
		player_distance_x =  get_parent().get_node("Bike").position.x
	
	var speed_increase = (abs(position.x - player_distance_x)/100 + 1 )
	position.x -= move_speed * delta * speed_increase
	var new_limit_x = $SandstormVolume.material.get_shader_parameter("box_limit_x") - move_speed * delta * speed_increase
	$SandstormVolume.material.set_shader_parameter("box_limit_x", new_limit_x)
	$SandVolume.material.set_shader_parameter("box_limit_x", new_limit_x)


func _on_audio_stream_player_3d_finished():
	$AudioStreamPlayer3D.play()
