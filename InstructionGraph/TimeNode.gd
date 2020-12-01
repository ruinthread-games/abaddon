extends GraphNode

var value = "Time"
var time_value = 0
var active = false
# Called when the node enters the scene tree for the first time.
func _ready():
	set_slot(0,false,0,Color(0), true, 0, Color(0,1,1,1))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if active:
		time_value += delta
		get_node("Label").text = "%10.1f" %(time_value) #String(time_value)
