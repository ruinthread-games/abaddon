extends GraphNode

var value = "SingleMath"

var function_label = 'null'

func _ready():
	set_slot(1,true,0,Color(0,1,1,1), true, 0, Color(0,1,1,1))
	#set_slot(1,false,0,Color(0,1,1,1), true, 0, Color(0,1,1,1))

func _on_ItemList_item_selected(index):
	print("itemlist selected ind", index)
	function_label = ["sin","cos","tan","exp", "square", "sqrt", "abs","sign"][index]

func set_function_label(new_label):
	function_label = new_label
	var label_indices = {"sin":0,"cos":1,"tan":2,"exp":3,"square":4,"sqrt":5, "abs":6, "sign":7}
	get_node("ItemList").select(label_indices[new_label])

func real_function(input):
	if function_label == "abs":
		return abs(input)
	if function_label == "sin":
		return sin(input)
	elif function_label == "cos":
		return cos(input)
	elif function_label == "tan":
		return tan(input)
	elif function_label == "exp":
		return exp(input)
	elif function_label == "square":
		return pow(input,2.0)
	elif function_label == "sqrt":
		return sqrt(input)
	elif function_label == "sign":
		if input == 0:
			return 0
		return input / abs(input)
	return 0

func array_function(input):
	var result = []
	for i in range(len(input)):
		result.append(real_function(input[i]))
	return result

func apply_function(input):
	if typeof(input) == TYPE_ARRAY:
		return array_function(input)
	else:
		return real_function(input)
	
	
