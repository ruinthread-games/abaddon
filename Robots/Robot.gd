extends Spatial

#var elevation_function = load("res://Planet/planet_elevation.gd").new()
var elevation_function
var spawn_target
var robot_fleet_id
var updates = 0
var target_reached = false
var movement_target = Vector3(0,0,0)
var previous_forwards = Vector3(0,0,0)
var robot_status_rect

var obstacle_avoidance_angle = 0

var is_moving = false
var is_mining = false
var is_building_gravity_beacon = false
var is_building_habitation_structure = false
var is_building_power_station = false
var is_attacking = false
var is_dead = false

onready var planet = get_node("../../Planet/Terrain")
onready var main = get_node("../..")

var charge = 100.0
var max_charge = 100.0
var charge_depletion_rate = 1
var building_progress = -1
var mining_progress = 0
var attack_progress = 0
var min_opponent_dist = 4000.0
var nearest_opponent = null
var nearest_power_station = null
var power_station_charge_distance_threshold = 30.0
var charge_over_time = 0.0
var in_power_station_charging_range = false
var nearest_power_station_charge_distance = INF
var target_im 

var use_collision = false
var draw_target_vectors = false

var deposits_in_range = null

var death_animation_finished = false

func _ready():
	charge_depletion_rate = get_node("/root/SettingsEdit").get_setting("charge_depletion")
	draw_target_vectors = get_node("/root/SettingsEdit").get_setting("draw_target_vectors")
	#elevation_function.initialise_noise()
	#print("ready ", robot_fleet_id)	
	#planet = main.planet
	transform.origin *= 4
	robot_status_rect.color = Color(0,1,0)
	target_im = ImmediateGeometry.new()
	add_child(target_im)

func set_instructions(output_pin, new_movement_target):
	if is_dead:
		return
	
	is_building_gravity_beacon = false
	is_building_habitation_structure = false
	is_building_power_station = false
	is_mining = false
	is_moving = false
	is_attacking = false
	# move 0, 1 long, 2 lat
	if output_pin == 0:
		is_moving = true
		movement_target = elevation_function.get_surface_coord(new_movement_target,1)
	
	# build 3 power, 4 gravity, 5 hab
	if output_pin == 3:
		is_building_power_station = true
	if output_pin == 4:
		is_building_gravity_beacon = true
	if output_pin == 5:
		is_building_habitation_structure = true
	
	# 9 mine, 10 sep
	if output_pin == 6:
		is_mining = true
	# 11 attack
	if output_pin == 7:
		is_attacking = true
	
	if output_pin == 8:
		is_dead = true
		update_status_rect()

func attack(delta):
	attack_progress = clamp(attack_progress-delta,0,1)
	if nearest_opponent:
		if transform.origin.distance_to(nearest_opponent.transform.origin) < 3.0:
			$AnimationPlayer.play("Attack")
			$AnimationPlayer.playback_speed = 0.6
			if attack_progress == 0:
				print(robot_fleet_id, ' landed hit on leviathan ', nearest_opponent.opponent_id)
				nearest_opponent.hits_taken += 1
				attack_progress = 1
				charge -= 5 * charge_depletion_rate

func build(delta):
	var structure_type = ''
	if is_building_gravity_beacon:
		structure_type = 'gravity_beacon'
	elif is_building_power_station:
		structure_type = 'power_station'
	elif is_building_habitation_structure:
		structure_type = 'habitation_structure'
	if building_progress == -1:
		var can_build = planet.can_build_at_position(transform.origin)
		if can_build:
			building_progress = main.request_build_structure(structure_type)
		else:
			return
	else:
		if is_building_gravity_beacon:
			$AnimationPlayer.play("PlaceBone")
		elif is_building_power_station:
			$AnimationPlayer.play("PlaceCrystal")
		elif is_building_habitation_structure:
			$AnimationPlayer.play("PlaceBrick")
		$AnimationPlayer.playback_speed = 0.6
		building_progress += delta
		charge -= 5.0*delta*charge_depletion_rate
		if building_progress > 5:
			building_progress = -1
			planet.spawn_structure(transform.origin,structure_type)

func mine(delta):
	# check if bot is near a resource
	#print('planet: ', planet)
	
	if not deposits_in_range == null:
		if deposits_in_range[0].deposit_type == 'Firstium':
			$AnimationPlayer.play("MineCrystal")
		if deposits_in_range[0].deposit_type == 'Secondium':
			$AnimationPlayer.play("MineBrick")
		if deposits_in_range[0].deposit_type == 'Thirdium':
			$AnimationPlayer.play("MineBone")
		$AnimationPlayer.playback_speed = 0.6
	
		mining_progress += delta
		charge -= 5.0*delta*charge_depletion_rate
		if mining_progress > 5:
			mining_progress = 0
			for deposit in deposits_in_range:
				if deposit.deposit_type == 'Firstium':
					main.firstium_amount += 5
				if deposit.deposit_type == 'Secondium':
					main.secondium_amount += 5
				if deposit.deposit_type == 'Thirdium':
					main.thirdium_amount += 1

func move_towards_target(delta):
	
	var sq_dist = movement_target.distance_squared_to(transform.origin)
	#print('sq dist: ', sq_dist)
	if sq_dist < 0.1:
		return
	$AnimationPlayer.play("Move")
	$AnimationPlayer.playback_speed = 3
	#print(robot_fleet_id, " is oscar mike ", (movement_target - transform.origin).length())
	var up = elevation_function.get_surface_normal(transform.origin)# transform.origin.normalized() 
	var movement_forwards = (movement_target - transform.origin).normalized()
#	movement_forwards = movement_forwards.rotated(up,obstacle_avoidance_angle)
	var movement_right = movement_forwards.cross(up).normalized()
	var corrected_forwards = movement_right.cross(up).normalized()
	#print("\t", corrected_forwards.dot(previous_forwards), "\t", corrected_forwards.dot(up))
	
	var movement_speed = 15
	var new_target_position = transform.origin + movement_speed * corrected_forwards.dot(movement_forwards) * delta*corrected_forwards
	
	# this would be super basic collision checking but bots get stuck, possible to pick alternate paths?
	if use_collision:
		var hashed = planet.hash_position(new_target_position)
		if hashed in planet.robot_map:
			if planet.robot_map[hashed][0] != self:
				obstacle_avoidance_angle += PI/6.0
				return
		obstacle_avoidance_angle = 0
	
	transform.origin = new_target_position
	charge -= delta*charge_depletion_rate
	var projected_point = elevation_function.get_surface_coord(transform.origin,1)
	transform.origin = projected_point
	transform = transform.looking_at(transform.origin-corrected_forwards,up)
	previous_forwards = corrected_forwards

func update_status_rect():
	var intensity = (charge / max_charge)
	if is_dead:
		robot_status_rect.color = Color(1,0,0)
	elif is_mining:
		robot_status_rect.color =  Color(intensity,intensity,0)
	elif is_building_gravity_beacon or is_building_habitation_structure or is_building_power_station:
		robot_status_rect.color = Color(0,intensity,intensity)
	elif is_attacking:
		robot_status_rect.color = Color(intensity,0,intensity)
	else:
		robot_status_rect.color = Color(0,intensity,0)

func update_sensory():
	var hashed_position = planet.hash_position(transform.origin)
	if hashed_position in planet.deposit_map:
		deposits_in_range = planet.deposit_map[hashed_position]
	else:
		deposits_in_range = null
	
	nearest_opponent = null
	for opponent in planet.opponent_list:
		var sq_dist = opponent.transform.origin.distance_squared_to(transform.origin)
		if sq_dist < min_opponent_dist and not opponent.is_dead:
			nearest_opponent = opponent
			min_opponent_dist = sq_dist
	
	in_power_station_charging_range = false
	nearest_power_station_charge_distance = INF
	for power_station in planet.power_station_list:
		var sq_dist = power_station.transform.origin.distance_squared_to(transform.origin)
		if sq_dist < nearest_power_station_charge_distance:
			if sq_dist < power_station_charge_distance_threshold:
				in_power_station_charging_range = true
			nearest_power_station = power_station
			nearest_power_station_charge_distance = max(0.01,sq_dist)
	
func set_death_animation_finished(name):
	death_animation_finished = true

func _process(delta):
	if is_dead:
		if not death_animation_finished:
			$AnimationPlayer.play("Death")
		return
	if charge < 0:
		kill()
		return
	
	if draw_target_vectors:
		target_im.clear()
		target_im.begin(Mesh.PRIMITIVE_LINES)
		target_im.add_vertex(Vector3(0,0,0))
		target_im.add_vertex(transform.inverse()*movement_target)
		target_im.end()
	
	updates += 1
	#var target_elevation = elevation_function.get_elevation(spawn_target)
	var to_surface = elevation_function.get_surface_coord(spawn_target) - transform.origin
	
	if not target_reached:
		if transform.origin.distance_squared_to(spawn_target) > 1:
			transform.origin += delta * 50 * to_surface.normalized()
		else:
			#print("snap ", robot_fleet_id, " upd ", updates)
			transform.origin = spawn_target
			target_reached = true
			movement_target = spawn_target
			#movement_target = 100*elevation_function.get_elevation(-spawn_target)*(-spawn_target+Vector3(27.2,44.6,2.8)).normalized()
			
	if target_reached:
		if is_moving:
			move_towards_target(delta)
		if is_mining:
			mine(delta)
		if is_building_gravity_beacon or is_building_habitation_structure or is_building_power_station:
			build(delta)
		if is_attacking:
			attack(delta)
	update_status_rect()
	update_sensory()
		
	if in_power_station_charging_range:
#		print(robot_fleet_id, 'dist: ', nearest_power_station_charge_distance, ' delta charge: ',  50 * delta * 1000.0 / nearest_power_station_charge_distance, ' charge: ', charge)
		charge_over_time = max_charge# clamp(charge + 50 * delta * 400.0 / nearest_power_station_charge_distance,0, max_charge)
	
	var delta_charge = max(0,charge_over_time-5*delta)
	charge_over_time = clamp(charge_over_time-delta_charge,0,max_charge)
	charge = clamp(charge+delta_charge,0,max_charge)

func kill():
	is_mining = false
	is_building_gravity_beacon =false
	is_building_habitation_structure = false
	is_building_power_station = false
	is_moving = false
	is_attacking = false
	is_dead = true
	
	$AnimationPlayer.play("Death")
	$AnimationPlayer.connect("animation_finished",self,"set_death_animation_finished")
	
	update_status_rect()
