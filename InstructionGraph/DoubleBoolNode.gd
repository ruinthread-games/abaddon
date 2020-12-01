extends GraphNode

var value = "DoubleBool"

var function_label = 'null'

func _ready():
	set_slot(0,true,0,Color(1,0,0,1), true, 0, Color(1,0,0,1))
	set_slot(2,true,0,Color(1,0,0,1), false, 0, Color(0,1,1,1))

func _on_ItemList_item_selected(index):
	function_label = ["and", "or"][index]
	print('selected function ', function_label)

func set_function_label(new_label):
	function_label = new_label
	var label_indices = {"and":0,"or":1}
	get_node("ItemList").select(label_indices[new_label])

func array_array_operation(first,second):
	var result = []
	for i in range(len(first)):
		result.append(real_real_operation(first[i],second[i]))
	return result

func real_array_operation(first, second):
	var result = []
	for i in range(len(second)):
		result.append(real_real_operation(first,second[i]))
	return result
	
func array_real_operation(first, second):
	var result = []
	for i in range(len(first)):
		result.append(real_real_operation(first[i],second))
	return result
	
func real_real_operation(first,second):
	if function_label == "and":
		return first and second
	elif function_label == "or":
		return first or second
	else:
		return 0

func apply_operation(first, second):
	if typeof(first) == TYPE_ARRAY and typeof(second) == TYPE_ARRAY:
		return array_array_operation(first, second)
	elif typeof(first) == TYPE_ARRAY and typeof(second) != TYPE_ARRAY:
		return array_real_operation(first,second)
	elif typeof(first) != TYPE_ARRAY and typeof(second) == TYPE_ARRAY:
		return real_array_operation(first,second)
	else:
		return real_real_operation(first,second)
	
