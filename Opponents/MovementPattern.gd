extends Spatial

var elevation_function = load("res://Planet/planet_elevation.gd").new()
var rng = RandomNumberGenerator.new()
var planet
var pattern_points = []

func _ready():
	elevation_function.initialise_noise(get_node("/root/SettingsEdit").get_setting('abaddon_seed'))

func generate_pattern(rng_seed):
	rng.seed = rng_seed
	var origin_phi = rng.randf_range(0,2.0*PI)
	var origin_theta = rng.randf_range(0,2.0*PI)
	
	var pattern_origin = elevation_function.get_surface_coord_spherical(origin_theta,origin_phi,20)
	while(pattern_origin.length() < 120):
		origin_phi = rng.randf_range(0,2.0*PI)
		origin_theta = rng.randf_range(0,2.0*PI)
		pattern_origin = elevation_function.get_surface_coord_spherical(origin_theta,origin_phi,20)
	#traverse_canonical_directions(pattern_origin)
	traverse_multi_directions(pattern_origin)

func get_directions(number_of_directions):
	var unit = Vector2(1,0)
	var dirs = []
	for i in range(number_of_directions):
		dirs.append(unit.rotated(i*2.0*PI/number_of_directions))
	return dirs

func traverse_multi_directions(origin):
	var all_heights = []
	var add_directions = []
	var all_bounds = []
	var number_of_directions = 30
	for _i in range(number_of_directions):
		all_heights.append([])
		add_directions.append(true)
		all_bounds.append(Vector3(origin))
	var origin_spherical = elevation_function.to_spherical(origin)
	var stepsize = 0.2 * (2.0*PI) / 360.0
	var directions = get_directions(number_of_directions)
	for step in range(150):
		for i in range(number_of_directions):
			var dir = directions[i]
			var delta = step * stepsize * dir
			var height = elevation_function.get_elevation_spherical(origin_spherical[2]+delta.x,origin_spherical[1]+delta.y)
			if height > 100.0 and add_directions[i]:
				all_heights[i].append(height)
				all_bounds[i] = elevation_function.get_surface_coord_spherical(origin_spherical[2]+delta.x,origin_spherical[1]+delta.y)
			else:
				add_directions[i] = false
	all_bounds.append(all_bounds[0])
	
	var path = get_node("Path")
	path.curve.clear_points()
	for i in range(number_of_directions+1): 
		var im1 = i-1 if i > 0 else number_of_directions -1
		var ip1 = (i+1) % number_of_directions
		#var ip2 = (i+2) % number_of_directions
		
		var cur_forwards = -(all_bounds[ip1]-all_bounds[im1]).normalized()
		var next_forwards = (all_bounds[ip1]-all_bounds[im1]).normalized()
		var control_strength = 0.1*30.0
		path.curve.add_point(all_bounds[i],control_strength*cur_forwards,control_strength*next_forwards)
	
	var baked_points = path.curve.get_baked_points()
	for point in baked_points:
		pattern_points.append(elevation_function.get_surface_coord(point))
	
	make_ribbon(pattern_points)
	
	
func traverse_canonical_directions(origin):
	var heights_north = []
	var heights_south = []
	var heights_east = []
	var heights_west = []
	var origin_spherical = elevation_function.to_spherical(origin)
	var add_north = true
	var add_south = true
	var add_east = true
	var add_west = true
	var stepsize = 0.2 * (2.0*PI) / 360.0
	get_directions(8)
	for i in range(100):
		var delta = i * stepsize
		var height_north = elevation_function.get_elevation_spherical(origin_spherical[2]+delta,origin_spherical[1])
		if height_north > 100.0 and add_north:
			heights_north.append(height_north)
		else:
			add_north = false
			
		var height_south = elevation_function.get_elevation_spherical(origin_spherical[2]-delta,origin_spherical[1])
		if height_south > 100.0 and add_south:
			heights_south.append(height_south)
		else:
			add_south = false
			
		var height_east = elevation_function.get_elevation_spherical(origin_spherical[2],origin_spherical[1]+delta)
		if height_east > 100.0 and add_east:
			heights_east.append(height_east)
		else:
			add_east = false
			
		var height_west = elevation_function.get_elevation_spherical(origin_spherical[2],origin_spherical[1]-delta)
		if height_west > 100.0 and add_west:
			heights_west.append(height_west)
		else:
			add_west = false
	
	var delta_north = (len(heights_north)-1) * stepsize
	var delta_south = -(len(heights_south)-1) * stepsize
	var delta_east = (len(heights_east)-1) * stepsize
	var delta_west = -(len(heights_west)-1) * stepsize
	var height_offset =  0.0
	var bound_north = elevation_function.get_surface_coord_spherical(origin_spherical[2]+delta_north,origin_spherical[1],height_offset)
	var bound_south = elevation_function.get_surface_coord_spherical(origin_spherical[2]+delta_south,origin_spherical[1],height_offset)
	var bound_west = elevation_function.get_surface_coord_spherical(origin_spherical[2],origin_spherical[1]+delta_west,height_offset)
	var bound_east = elevation_function.get_surface_coord_spherical(origin_spherical[2],origin_spherical[1]+delta_east,height_offset)
#	make_marker(bound_north)
#	make_marker(bound_south)
#	make_marker(bound_east)
#	make_marker(bound_west)
#	make_marker(origin)
	
	print(delta_north,"\t",delta_west,"\t",delta_south,"\t", delta_east)
	print(bound_north.length(),"\t",bound_west.length(),"\t",bound_south.length(),"\t",bound_east.length())
	
	var path = get_node("Path")
	path.curve.clear_points()
	for i in range(5): 
		var im1 = i-1 if i > 0 else 3
		var ip1 = (i+1) % 4
		var ip2 = (i+2) % 4
		var points = [bound_north,bound_west,bound_south,bound_east,bound_north]
		var cur_forwards = -(points[ip1]-points[im1]).normalized()
		var next_forwards = (points[ip1]-points[im1]).normalized()
		var control_strength = 30.0
		path.curve.add_point(points[i],control_strength*cur_forwards,control_strength*next_forwards)
	
	var baked_points = path.curve.get_baked_points()
	for point in baked_points:
		pattern_points.append(elevation_function.get_surface_coord(point))
	
	make_ribbon(pattern_points)

func make_marker(position):
	var marker = MeshInstance.new()
	marker.mesh = CubeMesh.new()
	marker.transform.origin = position
	#marker.transform = marker.transform.scaled(Vector3(10,10,10))
	self.add_child(marker)


func make_ribbon(points):
	for i in len(points):
		#var im1 = i-1 if i > 0 else len(points) -1
		var ip1 = (i+1) % len(points)
		var ip2 = (i+2) % len(points)
		
		var current_up = points[i].normalized()
		var current_forwards = (points[ip1]-points[i]).normalized()
		var current_right = current_forwards.cross(current_up)
		
		var next_up = points[ip1].normalized()
		var next_forwards = (points[ip2]-points[ip1]).normalized()
		var next_right = next_forwards.cross(next_up)
		
		var width = 0.25
		var offset = 1.3
		var cur_point_p = elevation_function.get_surface_coord(points[i] + width*current_right,offset)
		var cur_point_m = elevation_function.get_surface_coord(points[i] - width*current_right,offset)
		var next_point_p = elevation_function.get_surface_coord(points[ip1] + width*next_right,offset)
		var next_point_m = elevation_function.get_surface_coord(points[ip1] - width*next_right,offset)
		
		if cur_point_p.length() < (100.0+offset):
			cur_point_p = cur_point_p.normalized()*(100.0+offset)
		if cur_point_m.length() < (100.0+offset):
			cur_point_m = cur_point_m.normalized()*(100.0+offset)
		if next_point_p.length() < (100.0+offset):
			next_point_p = next_point_p.normalized()*(100.0+offset)
		if next_point_m.length() < (100.0+offset):
			next_point_m = next_point_m.normalized()*(100.0+offset)
		
		var line_geom = get_node("ImmediateGeometry")

		if true:
			line_geom.begin(Mesh.PRIMITIVE_TRIANGLES)
			line_geom.add_vertex(cur_point_m)
			line_geom.add_vertex(cur_point_p)
			line_geom.add_vertex(next_point_m)

			line_geom.add_vertex(cur_point_p)
			line_geom.add_vertex(next_point_m)
			line_geom.add_vertex(next_point_p)
			line_geom.end()
		else:
			line_geom.begin(Mesh.PRIMITIVE_POINTS)
			line_geom.add_vertex(elevation_function.get_surface_coord(points[i],offset))
			line_geom.end()
