tool
extends BTNode
class_name BTComposite


#----- Methods -----
func get_bt_children():
	var res = []
	for child in get_children():
		if child.has_method('_Class_Type_BTNode_'):
			res.append(child)
	return res

func get_last_child():
	var pre = get_child_count() - 1
	while pre >= 0 and not get_child(pre).has_method('_Class_Type_BTNode_'):
		pre -= 1
	if pre >= 0:
		return get_child(pre)
	return null
