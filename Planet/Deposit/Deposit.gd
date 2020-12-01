tool
extends Spatial

var deposit_type
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_deposit_type(new_deposit_type):
	deposit_type = new_deposit_type
	var primary_colour
	if deposit_type == 'Firstium':
		primary_colour = Color(1,0,0)
		#get_node("FirstiumInstance").get_surface_material(0).set_shader_param("Primary", primary_colour)
		get_node("SecondiumInstance").visible = false
		get_node("ThirdiumInstance").visible = false
	elif deposit_type == 'Secondium':
		primary_colour = Color(0,0,1)
		get_node("FirstiumInstance").visible = false
		#get_node("SecondiumInstance").get_surface_material(0).set_shader_param("Primary", primary_colour)
		get_node("ThirdiumInstance").visible = false
	elif deposit_type == 'Thirdium':
		primary_colour = Color(1,0.8,0)
		get_node("FirstiumInstance").visible = false
		get_node("SecondiumInstance").visible = false
		#get_node("ThirdiumInstance").get_surface_material(0).set_shader_param("Primary", primary_colour)
	#print('prm colour: ', primary_colour)
	#print(get_node("MeshInstance").get_surface_material(0).get_shader_param("Primary"))
