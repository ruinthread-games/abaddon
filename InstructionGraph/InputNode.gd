extends GraphNode

var value = "InputNode"

var added_slots = 0
var slot_type_labels = []

var internal_data = null

func _ready():
	pass
	#set_slot(0,false,0,Color(0), true, 0, Color(0,1,1,1))

func add_slot(label_text,slot_type='number'):
	slot_type_labels.append([label_text,slot_type])
	var new_label = Label.new()
	new_label.text = label_text
	add_child(new_label)
	var colour
	if slot_type == 'number':
		colour = Color(0,1,1,1)
	if slot_type == 'bool':
		colour = Color(1,0,0,1)
	set_slot(added_slots,false,0,Color(0), true,0,colour)
	added_slots += 1

