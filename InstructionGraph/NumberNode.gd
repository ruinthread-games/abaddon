extends GraphNode

var value = "Number"
var old_text = "0"
var number = 0
var line_edit
var stored_label = 'num'

func _ready():
	set_slot(0,false,0,Color(0,1,1,1), true, 0, Color(0,1,1,1))
	line_edit = get_node("HBoxContainer/ValueEdit")
	#number = 0

func set_number(new_number):
	number = new_number
	old_text = String(number)
	get_node("HBoxContainer/ValueEdit").text = String(number)
	

func _on_LineEdit_text_changed(new_text):
	old_text = new_text


func _on_LineEdit_text_entered(new_text):
	var casted = float(new_text)
	if new_text != String(casted):
		line_edit.text = String(casted)
	number = casted
	print(number)


func _on_LineEdit_focus_exited():
	var casted = float(old_text)
	if old_text != String(casted):
		line_edit.text = String(casted)
	number = casted
	print(number)


func _on_NameEdit_text_changed(new_text):
	stored_label = new_text
