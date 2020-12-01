extends WorldEnvironment

var title_screen = false

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if title_screen:
		environment.dof_blur_far_distance = 300
		return
		
	var camera = get_node("/root/Main/CamBase/horizontal/vertical/Camera")
	var dist_to_origin = camera.transform.origin.length()
	environment.dof_blur_far_distance = dist_to_origin - 100.0
#	pass
