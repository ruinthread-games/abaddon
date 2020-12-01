extends GraphNode

var value = "OutputNode"
# Called when the node enters the scene tree for the first time.
func _ready():
	# move
	set_slot(0,true, 0, Color(1,1,1,1),false,0,Color(0))
	set_slot(1,true, 0, Color(0,1,1,1),false,0,Color(0))
	set_slot(2,true, 0, Color(0,1,1,1),false,0,Color(0))
	
	# build
	set_slot(5,true, 0, Color(1,1,1,1),false,0,Color(0))
	set_slot(6,true, 0, Color(1,1,1,1),false,0,Color(0))
	set_slot(7,true, 0, Color(1,1,1,1),false,0,Color(0))
	
	# mine
	set_slot(9,true, 0, Color(1,1,1,1),false,0,Color(0))
	# attack
	set_slot(11,true, 0, Color(1,1,1,1),false,0,Color(0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
