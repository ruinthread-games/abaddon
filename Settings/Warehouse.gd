extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var animations = [
	"Attack", 
	"Move", 
	"MineBone", 
	"PlaceBone", 
	"Move", 
	"MineBrick", 
	"PlaceBrick", 
	"Move", 
	"MineCrystal", 
	"PlaceCrystal",
	"Move"
	]
var current_animation_index = 0
var current_animation = animations[current_animation_index]


func change_animation(name):
	print('change anim!', name)
	current_animation_index += 1 
	if current_animation_index > len(animations) -1:
		current_animation_index = 0
	current_animation = animations[current_animation_index]

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.connect("animation_finished",self,"change_animation")

func _process(delta):
#	if current_animation == null:
	$AnimationPlayer.play(current_animation)
#	get_node("AnimationPlayer").is_playing()
