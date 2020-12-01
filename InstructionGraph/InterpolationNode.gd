extends GraphNode

var value = 'Interpolate'

func _ready():
	set_slot(0,true,0,Color(0,1,1,1), true, 0, Color(0,1,1,1))
	set_slot(1,true,0,Color(0,1,1,1), false, 0, Color(0,1,1,1))
	set_slot(2,true,0,Color(0,1,1,1), false, 0, Color(0,1,1,1))

func array_interpolate(first_array,second_array,third_array):
	var result_array = []
	for i in range(len(first_array)):
		result_array.append(real_interpolate(first_array[i],second_array[i],third_array[i]))
	return result_array
	
func real_interpolate(first,second,third):
	if typeof(first) == TYPE_BOOL:
		return second if first else third
	return lerp(second,third,first)# first * second + (1-first) * third

func interpolate(first,second,third):
	var first_is_array = typeof(first) == TYPE_ARRAY
	var second_is_array = typeof(second) == TYPE_ARRAY
	var third_is_array = typeof(third) == TYPE_ARRAY
	if first_is_array or second_is_array or third_is_array:
		var first_array = first if first_is_array else []
		var second_array = second if second_is_array else []
		var third_array = third if third_is_array else []
		for _i in range(max(max(len(first_array),len(second_array)),len(third_array))):
			if not first_is_array:
				first_array.append(first)
			if not second_is_array:
				second_array.append(second)
			if not third_is_array:
				third_array.append(third)
		return array_interpolate(first_array,second_array,third_array)
	else:
		return real_interpolate(first,second,third)
