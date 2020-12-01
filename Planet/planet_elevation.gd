#tool
extends Node


var noise = OpenSimplexNoise.new()

func _ready():
	pass
	
func initialise_noise(noise_seed):
	noise.seed = noise_seed
	noise.octaves = 9
	noise.lacunarity = 2.0
	noise.persistence = 0.65
	#print('set noise seed to ', noise.seed)
	
func get_elevation(world_coord):
	#var noise_value = 10 * noise.get_noise_3dv(noise_coord)
	var noise_value = 100.0*((1.0 + 0.5*3.85*abs(noise.get_noise_3dv(1.2*2.22*world_coord))) -0.03)
	#print(world_coord, noise_value)
	return noise_value

func to_cartesian(r, theta, phi):
	return Vector3(r*sin(theta)*cos(phi), r*sin(theta)*sin(phi), r*cos(theta))

func to_spherical(cartesian_position):
	var r = cartesian_position.length()
	# r, phi , theta
	return [r,atan2(cartesian_position.y,cartesian_position.x), acos(cartesian_position.z/r)]

func get_elevation_spherical(theta, phi):
	return get_elevation(to_cartesian(1,theta,phi))
	
func get_elevation_gradient(theta, phi):
	var delta = (2.0*PI)/360.0
	var height = get_elevation_spherical(theta, phi)
	var height_theta = get_elevation_spherical(theta + delta, phi)
	var height_phi = get_elevation_spherical(theta, phi + delta)
	
	var dh_dtheta = -(height_theta-height)/delta
	var dh_dphi = -(height_phi-height)/delta
	var cartesian = dh_dphi * Vector3(-sin(phi),cos(phi),0) + dh_dtheta * Vector3(cos(theta)*cos(phi), cos(theta)*sin(phi), -sin(theta))
	#print('spherical grad: ', dh_dtheta, "\t", dh_dphi,'\n\tcartesian:', cartesian)
	return cartesian.normalized()

func get_surface_coord_spherical(theta,phi,offset=0.0):
	#print('spher: ', offset)
	return get_surface_coord(to_cartesian(1.0,theta,phi),offset)

func get_surface_coord(world_coord,offset=0.0):
	var norm_coord = world_coord.normalized()
	return (get_elevation(norm_coord)+offset)*norm_coord
	
func get_surface_normal(world_coord):
	
	var up = world_coord.normalized()
	var fwd = up.cross(Vector3(up.y,up.z,up.x)).normalized()
	var right = up.cross(fwd).normalized()
	
	var first = get_surface_coord(up-0.05*fwd -0.05*right)
	var second = get_surface_coord(up-0.05*fwd +0.05*right)
	var third = get_surface_coord(up + 0.05*fwd + 0.05*right)
	return -(first-second).cross(first-third).normalized()
