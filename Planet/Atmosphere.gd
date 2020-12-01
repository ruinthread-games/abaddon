extends Spatial

var bubble_material = load("res://Planet/Bubble.tres")
var marching_cubes_mesh = preload("res://MarchingCubes/MarchingCubesMesh.tscn")
var base_atmosphere_bubble = preload("res://Planet/Bubble.tscn")
var bubble_list = []
var bubble_base_heights = []
var atmosphere_inner_boundary
var mesh_list = []

func update_gravity(new_gravitational_force):
	for i in range(len(bubble_list)):
		var bubble = bubble_list[i]
		var bubble_base_height = bubble_base_heights[i]
		bubble.transform.origin = bubble.transform.origin.normalized() * height_under_gravity(bubble_base_height,new_gravitational_force)
	pass

func height_under_gravity(height, gravitational_force):
	return height - 6.0*gravitational_force

# Called when the node enters the scene tree for the first time.
func _ready():
	# bubbles should cover -200, 200
	var bound_lower = -200.0
	var bound_upper = 200.0
	
	var cells_per_row = 5
	for i in range(cells_per_row):
		for j in range(cells_per_row):
			for k in range(cells_per_row):
				var mcmesh_inst = marching_cubes_mesh.instance()
				mcmesh_inst.MeshDimensions = ((bound_upper-bound_lower)/cells_per_row) * Vector3(1,1,1)
				mcmesh_inst.MeshOffset = (Vector3(bound_lower,bound_lower,bound_lower) + Vector3(i,j,k) * mcmesh_inst.MeshDimensions)
				add_child(mcmesh_inst)
				mesh_list.append(mcmesh_inst)
#				mcmesh_inst.mesh.surface_set_material(0,bubble_material)
#	add_bubble(Vector3(0,0,0), 15.0)

func update_meshes():
	for mesh_inst in mesh_list:
		mesh_inst.Regenerate()

func add_bubble(position, gravitational_force):
	print('add bubble at ', position)
	atmosphere_inner_boundary = get_node("AtmosphereInnerBoundary")
	var bubble_instance = base_atmosphere_bubble.instance()
	var base_height = position.length() + 20
#	bubble_instance.transform.origin = height_under_gravity(base_height,gravitational_force)* position.normalized()
#	atmosphere_inner_boundary.add_child(bubble_instance)
#	atmosphere_inner_boundary.move_child(bubble_instance,0)
#	bubble_list.append(bubble_instance)
#	bubble_base_heights.append(base_height)
	
	for mesh_inst in mesh_list:
		if mesh_inst.AddSphere(height_under_gravity(base_height,gravitational_force)* position.normalized(),40.0):
			if mesh_inst.Regenerate():
				mesh_inst.mesh.surface_set_material(0,bubble_material)
	
#	update_meshes()
#	var atmosphere_outer_boundary = get_node("AtmosphereInnerBoundary/AtmosphereOuterBoundary")
#	atmosphere_inner_boundary.move_child(atmosphere_outer_boundary,len(bubble_list))
	#atmosphere_outer_boundary.operation =CSGShape.OPERATION_INTERSECTION
