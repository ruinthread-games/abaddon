extends Spatial

var movement_pattern_points = []
var current_point_index = 0
var movement_target
var elevation_function
var previous_forwards
var opponent_id
var hits_taken = 0
var is_dead = false
var override_colour = null

var attack_cooldown = 0
var max_attack_cooldown = 2

onready var planet

var death_animation_finished = false

func _ready():
	# spawn on first movement pattern point
	current_point_index = 0
	transform.origin = movement_pattern_points[current_point_index]
	movement_target = movement_pattern_points[current_point_index+1]
	
	if override_colour:
		var mat_copy = $Armature/Skeleton/LeviathanApplied.mesh.surface_get_material(0).duplicate()
		mat_copy.albedo_color = override_colour
		var mesh_copy = $Armature/Skeleton/LeviathanApplied.mesh.duplicate()
		$Armature/Skeleton/LeviathanApplied.mesh = mesh_copy
		$Armature/Skeleton/LeviathanApplied.mesh.surface_set_material(0, mat_copy)

func death_animation(name):
	death_animation_finished = true
	return

func _process(delta):	
	if is_dead:
		if not death_animation_finished:
			$AnimationPlayer.play("Death")
		return
	if hits_taken > 10:
		kill()
		return
		
	attack_cooldown = clamp(attack_cooldown-delta,0,max_attack_cooldown)
	var current_point_index_p1 = (current_point_index+1) % len(movement_pattern_points)
	#print('dist 2 targ: ', transform.origin.distance_squared_to(movement_target), "\t", current_point_index)
	while transform.origin.distance_squared_to(movement_target) < 1.0:
		current_point_index = current_point_index_p1
		current_point_index_p1 = (current_point_index+1) % len(movement_pattern_points)
		movement_target = movement_pattern_points[current_point_index_p1]
	move_towards_target(delta)
	
	if any_target_in_range() and attack_cooldown == 0:
		spawn_attack()

func any_target_in_range():
	var hashed_list = planet.hash_position_with_neighbours(transform.origin,1)
	
	for hashed in hashed_list:
		if hashed in planet.robot_map:
			for robot in planet.robot_map[hashed]:
				if not robot.is_dead and robot.target_reached:
					return true
	return false
	
func spawn_attack():
	$AnimationPlayer.play("Attack")
	var hashed_list = planet.hash_position_with_neighbours(transform.origin,1)
	#print('spawn attack: ', hashed_list)
	var hits = 0
	attack_cooldown = max_attack_cooldown
	for hashed in hashed_list:
		if hashed in planet.robot_map:
			var collisions = planet.robot_map[hashed]
			for robot in collisions:
				if hits >= 2:
					return
				if not robot.is_dead and robot.target_reached:
					robot.kill()
					hits += 1

func move_towards_target(delta):
	if $AnimationPlayer.current_animation == "Attack":
		return
	$AnimationPlayer.play("Walk")
	$AnimationPlayer.playback_speed = 1.15
	var init_origin = transform.origin
	var up = elevation_function.get_surface_normal(transform.origin.normalized())
	var movement_forwards = (movement_target - transform.origin).normalized()
	var movement_right = movement_forwards.cross(up).normalized()
	var corrected_forwards = movement_right.cross(up).normalized()
	
	transform.origin += 1 * corrected_forwards.dot(movement_forwards) * delta*corrected_forwards
	var projected_point = elevation_function.get_surface_coord(transform.origin,0)
	transform.origin = projected_point
	transform = transform.looking_at(transform.origin+corrected_forwards,up)
	
	if false and up.dot(movement_target.normalized()) > 0.99:
		print('opponent: ', opponent_id)
		print('\theight difference: ', transform.origin.length() - movement_target.length())
		print('\tdist targ: ', transform.origin.distance_to(movement_target))
		print('\tdistance moved: ', transform.origin.distance_to(init_origin))
		print('\ttarg to surf: ', movement_target.distance_to(elevation_function.get_surface_coord(movement_target)))
	previous_forwards = corrected_forwards

func kill():
	print('Leviathan killed!')
	$AnimationPlayer.play("Death")
	$AnimationPlayer.connect("animation_finished",self,"death_animation")
	death_animation_finished = false
	is_dead = true
