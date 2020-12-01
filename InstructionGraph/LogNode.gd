extends GraphNode

var value = 'log'
# Called when the node enters the scene tree for the first time.
func _ready():
	set_slot(0,true,0,Color(0,1,1,1), true, 0, Color(0,1,1,1))

func log(input):
	var log_str = ''
	if typeof(input) == TYPE_ARRAY:
		for i in range(min(len(input), 50)):
			log_str += (String(input[i])+"\n")
	else:
		log_str = String(input)
	return log_str
