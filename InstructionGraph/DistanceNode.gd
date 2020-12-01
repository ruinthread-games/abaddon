extends GraphNode

var value = 'Distance'

# Called when the node enters the scene tree for the first time.
func _ready():
	set_slot(0,true,0,Color(0,1,1,1), true, 0, Color(0,1,1,1))
	set_slot(1,true,0,Color(0,1,1,1), false, 0, Color(0))
	set_slot(2,true,0,Color(0,1,1,1), false, 0, Color(0))
	set_slot(3,true,0,Color(0,1,1,1), false, 0, Color(0))

func real_function(first,second,third,fourth):
	var diff_longitude = abs(first-third)# min(abs(first-third), 2.0*PI - abs(first-third))
	var diff_latitude = abs(second-fourth)# min(abs(second-fourth), 2.0*PI - abs(second-fourth))
	var dist = 1000*(diff_longitude + diff_latitude)
	#print(first,'|',second,'\t',third,'|',fourth)
	return dist

func array_function(first_array,second_array,third_array,fourth_array):
	var result_array = []
	for i in range(len(first_array)):
		result_array.append(real_function(first_array[i],second_array[i],third_array[i],fourth_array[i]))
	return result_array

func get_distance(first,second,third,fourth):
	#print('get distance')
	var first_is_array = typeof(first) == TYPE_ARRAY
	var second_is_array = typeof(second) == TYPE_ARRAY
	var third_is_array = typeof(third) == TYPE_ARRAY
	var fourth_is_array = typeof(fourth) == TYPE_ARRAY
	
	if first_is_array or second_is_array or third_is_array or fourth_is_array:
		var first_array = first if first_is_array else []
		var second_array = second if second_is_array else []
		var third_array = third if third_is_array else []
		var fourth_array = fourth if fourth_is_array else []
		for _i in range(max(max(len(first_array),len(second_array)),max(len(third_array),len(fourth_array)))):
			if not first_is_array:
				first_array.append(first)
			if not second_is_array:
				second_array.append(second)
			if not third_is_array:
				third_array.append(third)
			if not fourth_is_array:
				fourth_array.append(fourth)
		return array_function(first_array,second_array,third_array,fourth_array)
	else:
		return real_function(first,second,third,fourth)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
