#tool
extends MeshInstance

var surface_material = load("res://Planet/Terrain/Terrain.tres")
var elevation_function = load("res://Planet/planet_elevation.gd").new()
var base_deposit = preload("res://Planet/Deposit/Deposit.tscn")
var base_habitation_structure = preload("res://Planet/Structures/HabitationStructure/HabitationStructure.tscn")
var base_power_station = preload("res://Planet/Structures/PowerStation/PowerStation.tscn")
var base_gravity_beacon = preload("res://Planet/Structures/GravityBeacon/GravityBeacon.tscn")

var base_tree = preload("res://Planet/Vegetation/tree.tscn")

var base_atmosphere = preload("res://Planet/Atmosphere.tscn")
var atmosphere

var base_map_pin = preload("res://Planet/MapPin/MapPin.tscn")

var base_movement_pattern = preload("res://Opponents/MovementPattern.tscn")
var base_opponent = preload("res://Opponents/leviathan.tscn")
var dark_opponent = preload("res://Opponents/leviathan.tscn")
onready var robot_fleet = get_node("../../RobotFleet")
var rng = RandomNumberGenerator.new()
var firstium_noise = OpenSimplexNoise.new()
var secondium_noise = OpenSimplexNoise.new()
var thirdium_noise = OpenSimplexNoise.new()

var deposit_list = []
var movement_pattern_list = []

var mdt = MeshDataTool.new()

var deposit_map = {}
var structure_map = {}
var number_of_gravity_beacons = 0
var habitation_structure_map = {}
var habitation_structure_positions = []
var tree_map = {}
var power_station_list = []

var robot_map = {}
var opponent_list = []

var environment_status

var number_of_opponents = 10

var marker_is_pinned = false
var pin_marker_button
var pin_marker_coords
var marker = null
var water 

var target_im

export var react_to_input = true

var victory = false

func hash_position(cartesian_position):
	var r = cartesian_position.length()
	
	var phi_degrees = int(atan2(cartesian_position.y,cartesian_position.x) * 360 / (2*PI))
	var theta_degrees = int(acos(cartesian_position.z/r) * 360 / (2*PI))
	var hashed = '%+04d %+04d' %[phi_degrees,theta_degrees]
	return hashed

func hash_spherical(phi, theta):
	var phi_degrees = phi * 360 / (2*PI)
	var theta_degrees = theta * 360 / (2*PI)
	var hashed = '%+04d %+04d' %[phi_degrees,theta_degrees]
	return hashed

func hash_position_with_neighbours(cartesian_position,number_of_neighbours):
	var r = cartesian_position.length()
	
	var phi_degrees = int(atan2(cartesian_position.y,cartesian_position.x) * 360 / (2*PI))
	var theta_degrees = int(acos(cartesian_position.z/r) * 360 / (2*PI))
	var hashed_list = []
	for i in range(-number_of_neighbours,number_of_neighbours+1):
		for j in range(-number_of_neighbours,number_of_neighbours+1):
			hashed_list.append('%+04d %+04d' %[phi_degrees+i,theta_degrees+j])
	return hashed_list

func _ready():
	number_of_opponents = get_node("/root/SettingsEdit").get_setting('leviathan_population')
	print('num opponents: ', number_of_opponents)
	target_im = ImmediateGeometry.new()
	add_child(target_im)
	
	VisualServer.set_debug_generate_wireframes(true)
	firstium_noise.seed = 295289
	firstium_noise.octaves = 3
	firstium_noise.lacunarity = 2.0
	firstium_noise.persistence = 0.65
	secondium_noise.seed = 1211139
	secondium_noise.octaves = 3
	secondium_noise.lacunarity = 2.0
	secondium_noise.persistence = 0.65
	thirdium_noise.seed = 100001
	thirdium_noise.octaves = 3
	thirdium_noise.lacunarity = 2.0
	thirdium_noise.persistence = 0.65
	rng.seed = 22
	elevation_function.initialise_noise(get_node("/root/SettingsEdit").get_setting('abaddon_seed'))
	mdt.create_from_surface(mesh, 0)
	
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i)#.normalized()
		# Push out vertex by noise.
		vertex = elevation_function.get_surface_coord(vertex)
		#spawn_deposit(vertex)
		mdt.set_vertex(i, vertex)
	# Calculate vertex normals, face-by-face.
	for i in range(mdt.get_face_count()):
		# Get the index in the vertex array.
		var a = mdt.get_face_vertex(i, 0)
		var b = mdt.get_face_vertex(i, 1)
		var c = mdt.get_face_vertex(i, 2)
		# Get vertex position using vertex index.
		var ap = mdt.get_vertex(a)
		var bp = mdt.get_vertex(b)
		var cp = mdt.get_vertex(c)
		# Calculate face normal.
		var n = (bp - cp).cross(ap - bp).normalized()
		# Add face normal to current vertex normal.
		# This will not result in perfect normals, but it will be close.
		mdt.set_vertex_normal(a, n + mdt.get_vertex_normal(a))
		mdt.set_vertex_normal(b, n + mdt.get_vertex_normal(b))
		mdt.set_vertex_normal(c, n + mdt.get_vertex_normal(c))
		
		spawn_deposit((ap+bp+cp)/3,n)

	# Run through vertices one last time to normalize normals and
	# set color to normal.
	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex_normal(i).normalized()
		mdt.set_vertex_normal(i, v)
		mdt.set_vertex_color(i, Color(v.x, v.y, v.z))

	mesh.surface_remove(0)
	mdt.commit_to_surface(mesh)
	mesh.surface_set_material(0,surface_material)
	
	for id in range(number_of_opponents):
		spawn_opponent(id)
	#mesh_instance = MeshInstance.new()
	environment_status = get_node("../../EnvironmentStatus")
	
	marker = base_map_pin.instance()
	self.add_child(marker)
	
	pin_marker_button = Button.new()
	pin_marker_button.text = "Create marker here?"
	self.add_child(pin_marker_button)
	pin_marker_button.visible = false
	pin_marker_button.connect("button_up",self,"place_pin_button_pressed")
	
	atmosphere = base_atmosphere.instance()
	add_child(atmosphere)
	water = get_node("../Water")
	water.mesh.surface_get_material(0).albedo_color = Color('#f9030e20')
	
func _process(delta):
	robot_map = {}
	# initialise robot and opponent maps
	if robot_fleet==null:
		return
	for robot in robot_fleet.robot_list:
		var hashed = hash_position(robot.transform.origin)
		if hashed in robot_map:
			robot_map[hashed].append(robot)
		else:
			robot_map[hashed] = [robot]
	var living_opponents = 0
	for opponent in opponent_list:
		if not opponent.is_dead:
			living_opponents+=1
	environment_status.get_node("ThreatLevel").text = "-Threat Level: %d/%d Leviathans remaining" %[living_opponents,len(opponent_list)]

func get_aligned_orientation(position):
	var up = position.normalized()
	var forwards = up.cross(Vector3(up.y,up.z,up.x)).normalized()
	var forwards_x_proj = abs(forwards.dot(Vector3(1,0,0)))
	var forwards_y_proj = abs(forwards.dot(Vector3(0,1,0)))
	var forwards_z_proj = abs(forwards.dot(Vector3(0,0,1)))
	var right
	if  forwards_x_proj > forwards_y_proj and forwards_x_proj > forwards_z_proj:
		right = up.cross(Vector3(1,0,0)).normalized()
	elif forwards_y_proj > forwards_x_proj and forwards_y_proj > forwards_z_proj:
		right = up.cross(Vector3(0,1,0)).normalized()
	else:
		right = up.cross(Vector3(0,0,1)).normalized()
	forwards = up.cross(right).normalized()
	
	return [forwards,right,up]

func update_trees():
	for position in habitation_structure_positions:
		var spherical = elevation_function.to_spherical(position)
		
		var orientation = get_aligned_orientation(position)
		var forwards = orientation[0]
		var right = orientation[1]
		var up = orientation[2]
		
		var reach = 5
		for i in range(-reach,reach):
			for j in range(-reach,reach):
				var tree_pos = position+i*(4+rng.randf_range(-1,1))*forwards+j*(4+rng.randf_range(-1,1))*right
				var hashed = hash_position(tree_pos)
				if abs(i) > 1 or abs(j) > 1:
					var phi = spherical[1]+i/30.0
					var theta = spherical[2]+j/30.0
#					var hashed = hash_spherical(phi,theta)
					
					if hashed in tree_map:
						#update tree
						pass
					else:
						#spawn new tree
						var tree_instance = base_tree.instance()
						tree_instance.transform.origin = elevation_function.get_surface_coord(tree_pos)
						
						#elevation_function.get_surface_coord_spherical(theta+rng.randf_range(-0.01,0.01),phi+rng.randf_range(-0.01,0.01))
						var dist_to_hab = tree_pos.distance_to(position) / 10.0
						var skip_tree = rng.randf_range(0,1) / dist_to_hab < 0.5
						if tree_instance.transform.origin.length() < 101.0 or skip_tree:
							# water plants go here?
							tree_map[hashed] = null
						else:
							#var up = tree_instance.transform.origin.normalized()
							#var forwards = up.cross(Vector3(up.y,up.z,up.x)).normalized()
							tree_instance.transform = tree_instance.transform.looking_at(tree_instance.transform.origin+forwards,up)
							add_child(tree_instance)
							tree_map[hashed] = tree_instance
				else:
					tree_map[hashed] = null

func place_pin_button_pressed():
	get_node('/root/Main/RobotInstructions/InstructionsGraph').add_map_pin_node(pin_marker_coords,marker)
	marker = base_map_pin.instance()
	add_child(marker)

func _input(event):
	if not react_to_input:
		return
	if event is InputEventMouse:
		var ray_length = 1000.0
		var camera = get_node("/root/Main/CamBase/horizontal/vertical/Camera")
		
		var cam_pos = camera.transform.origin
		var from = camera.project_ray_origin(get_viewport().get_mouse_position())
		var dir = camera.project_ray_normal(get_viewport().get_mouse_position())# event.position)
		
		var to = from + 1000 * dir
		
		if false:
			target_im.clear()
			target_im.begin(Mesh.PRIMITIVE_LINES)
			target_im.add_vertex(from)
			target_im.add_vertex(to)
			target_im.end()
			
			target_im.begin(Mesh.PRIMITIVE_LINES)
			target_im.add_vertex(from + Vector3(0,5,0))
			target_im.add_vertex(from - Vector3(0,5,0))
			target_im.end()
		
		var cam_dist_to_origin = floor(camera.transform.origin.length())
		
		if pin_marker_button.get_position().distance_to(event.position) > 100:
			marker_is_pinned = false
			pin_marker_button.visible = false
		if marker_is_pinned:
			return
				
		if not marker_is_pinned:
			marker.visible = false
		var hit = false
		for i in range(0, cam_dist_to_origin+500):
			for j in range(10):
				var step_length = i + 0.1 * j
				var surf_coord = elevation_function.get_surface_coord(from+step_length*dir,0)
				if abs(surf_coord.length()-(from+step_length*dir).length()) < 0.1:
					hit = true
					if not marker_is_pinned:
						marker.visible = true
						marker.transform.origin = surf_coord
						var up = elevation_function.get_surface_normal(surf_coord)
						var fwd = Vector3(up.y,up.z,up.x).cross(up).normalized()
						marker.transform = marker.transform.looking_at(surf_coord + fwd, up)
					if event is InputEventMouseButton and event.pressed and event.button_index == 1:
						var spherical = elevation_function.to_spherical(surf_coord)
						pin_marker_button.text = 'Create pin at %d° %d°?' %[spherical[1]*360.0/(2.0*PI),spherical[2]*360.0/(2.0*PI)]
						pin_marker_coords = [spherical[1],spherical[2],surf_coord.x, surf_coord.y, surf_coord.z]
						marker_is_pinned = true
						pin_marker_button.visible = true
						pin_marker_button.set_position(event.position+Vector2(10,0))
					break
			if hit:
				break
	else:		
		if event is InputEventKey and Input.is_key_pressed(KEY_P):
			var vp = get_viewport()
			vp.debug_draw = (vp.debug_draw + 1 ) % 4
		
func can_build_at_position(position):
	var hashed = hash_position(position)
	if hashed in structure_map:
		return false
	else:
		return true

func init_deposit(position,normal,deposit_type):
	var hashed = hash_position(position)
	if hashed in deposit_map:
		return
		#deposit_map[hashed].append(deposit_instance)
		
	var deposit_instance = base_deposit.instance()
	deposit_map[hashed] = [deposit_instance]
	
	deposit_instance.set_deposit_type(deposit_type)
	deposit_instance.transform.origin = position
	var up = lerp(normal, position.normalized(), 1.0)
	var right = up.cross(Vector3(up.y,up.z,up.x)).normalized()
	right = right.rotated(up,rng.randf_range(0,6.28))
	var forwards = up.cross(right).normalized()
	
	if deposit_type == 'Secondium':
		var orientation = get_aligned_orientation(position)
		forwards = orientation[0]
		right = orientation[1]
	deposit_instance.transform = deposit_instance.transform.looking_at(position + forwards,up)
	deposit_list.append(deposit_instance)
	add_child(deposit_instance)
	
	

func get_gravity_force():
	return 2.3 + number_of_gravity_beacons * 0.73

func get_atmosphere_coverage():
	var bubble_radius = 6* (1.0- 0.05*abs(get_gravity_force() - 10.0))
	
	# this 'calculation' is totally fake :)
	# circle - circle intersection formula: https://mathworld.wolfram.com/Circle-CircleIntersection.html
	var coverage = 0
	for i in range(len(habitation_structure_positions)):
		for j in range(i):
			var first_position = habitation_structure_positions[i]
			var second_position = habitation_structure_positions[j]
			coverage += PI * bubble_radius * bubble_radius / (4*PI*100*100/3)
			var inter_bubble_distance = first_position.distance_to(second_position)
			var overlap = 2 * bubble_radius - inter_bubble_distance
			if inter_bubble_distance < 2 * bubble_radius:
				coverage -= 1 * overlap * sqrt(overlap) / (4*PI*100*100/3)
#	print('grav force: ', get_gravity_force(), ' radius: ', bubble_radius)
#	print('\tnum hab structs: ', len(habitation_structure_positions), ' atmosphere coverage: ', coverage)
	
	var clamped_coverage = clamp(100*coverage,0,100)
	
	if clamped_coverage == 100 and not victory:
		var popup = AcceptDialog.new()
		popup.dialog_text = "Congratulations, 100% atmosphere coverage attained. The moon Abaddon is now habitable, you win! You have unlocked a new setting."
		add_child(popup)
		popup.popup_centered()
		victory = true
		get_node("/root/SettingsEdit").settings['victory'] = true
		get_node("/root/SettingsEdit").save_settings()
	return clamped_coverage

func spawn_structure(position,structure_type):
	print('planent spawn structure ', structure_type, ' at ', position)
	var structure_instance = null
	if structure_type == 'habitation_structure':
		habitation_structure_positions.append(position)
		structure_instance = base_habitation_structure.instance()
		var coverage = get_atmosphere_coverage()
		environment_status.get_node("AtmosphereLevel").text = '-Atmosphere level: %d%% coverage' %int(coverage)
		atmosphere.add_bubble(position,get_gravity_force())
		water.mesh.surface_get_material(0).albedo_color = lerp(Color('#f9030e20'),Color('#ec0cc0f7'), coverage/100.0)
		update_trees()
	elif structure_type == 'gravity_beacon':
		structure_instance = base_gravity_beacon.instance()
		number_of_gravity_beacons += 1
		environment_status.get_node("GravityLevel").text = '-Gravity level: %2.1f N' %get_gravity_force()
		atmosphere.update_gravity(get_gravity_force())
	elif structure_type == 'power_station':
		structure_instance = base_power_station.instance()
		power_station_list.append(structure_instance)
		
	structure_instance.transform.origin = position
	var up = position.normalized()
	var forwards = up.cross(Vector3(up.y,up.z,up.x)).normalized()
	structure_instance.transform = structure_instance.transform.looking_at(position + forwards,up)
	structure_map[hash_position(position)] = structure_instance
	add_child(structure_instance)

func spawn_deposit(position,normal):
	if firstium_noise.get_noise_3dv(2*position) > 0.23 and position.length() > 105:
		init_deposit(position, normal, 'Firstium')
	if secondium_noise.get_noise_3dv(3*position) > 0.3 and position.length() > 105:
		init_deposit(position, normal, 'Secondium')
	if thirdium_noise.get_noise_3dv(0.5*position) > 0.32 and position.length() > 105:
		init_deposit(position, normal, 'Thirdium')

func spawn_opponent(id):
	var movement_pattern_instance = base_movement_pattern.instance()
	add_child(movement_pattern_instance)
	movement_pattern_instance.generate_pattern(rng.randi())
	movement_pattern_instance.visible = false
	movement_pattern_list.append(movement_pattern_instance)
	
	var opponent_instance = null
	if rng.randf_range(0,1) > 0.01:
		opponent_instance = base_opponent.instance()
	else:
		opponent_instance = dark_opponent.instance()
		var leviathan_colours = [Color('#595759')]
		var colour_index = rng.randi_range(0,len(leviathan_colours)-1)
		opponent_instance.override_colour = leviathan_colours[colour_index]
	
	opponent_instance.elevation_function = elevation_function
	opponent_instance.movement_pattern_points = movement_pattern_instance.pattern_points
	opponent_instance.opponent_id = id
	opponent_instance.planet = self
		
	add_child(opponent_instance)
	opponent_list.append(opponent_instance)
