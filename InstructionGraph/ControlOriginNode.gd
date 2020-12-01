extends GraphNode

var value = "ControlOrigin"

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	set_slot(0,false,0,Color(0), true, 0, Color(1,1,1,1))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
