extends GraphNode

var value = "Conditional"

var comparison_operation = "equals"

# Called when the node enters the scene tree for the first time.
func _ready():
	set_slot(0,true,0,Color(0,1,1,1), false, 0, Color(0,1,1,1))
	set_slot(2,true,0,Color(0,1,1,1), false, 0, Color(0,1,1,1))
	set_slot(1,false,0,Color(1,0,0,1), true, 0, Color(1,0,0,1))

func set_comparison_operation(operation):
	comparison_operation = operation
	var operation_indices = {"less_than":0, "equals":1, "not_equals":2, "greater_than":3}
	get_node("ItemList").select(operation_indices[operation])

func array_array_conditional(first,second):
	var result = []
	for i in range(len(first)):
		result.append(real_real_conditional(first[i],second[i]))
	return result

func real_array_conditional(first, second):
	var result = []
	for i in range(len(second)):
		result.append(real_real_conditional(first,second[i]))
	return result
	
func array_real_conditional(first, second):
	var result = []
	for i in range(len(first)):
		result.append(real_real_conditional(first[i],second))
	return result
	
func real_real_conditional(first,second):
	if comparison_operation == "equals":
		return abs(first - second) < 0.0001
	if comparison_operation == "less_than":
		return first < second
	if comparison_operation == "greater_than":
		return first > second
	if comparison_operation == "not_equals":
		return abs(first -second) > 0.0001
	return null

func apply_conditional(first,second):
	if typeof(first) == TYPE_ARRAY and typeof(second) == TYPE_ARRAY:
		return array_array_conditional(first, second)
	elif typeof(first) == TYPE_ARRAY and typeof(second) != TYPE_ARRAY:
		return array_real_conditional(first,second)
	elif typeof(first) != TYPE_ARRAY and typeof(second) == TYPE_ARRAY:
		return real_array_conditional(first,second)
	else:
		return real_real_conditional(first,second)


func _on_ItemList_item_selected(index):
	comparison_operation = ["less_than","equals", "not_equals", "greater_than"][index]
	print("set comparison to ", comparison_operation)
