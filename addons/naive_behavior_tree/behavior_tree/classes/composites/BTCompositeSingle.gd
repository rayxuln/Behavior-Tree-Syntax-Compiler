tool
extends BTComposite
class_name BTCompositeSingle

var running_child:BTNode = null
var current_child_index:int = 0

var random_children = null

#----- Methods -----
func child_running(running_task, reporter):
	running_child = running_task
	running()

func child_success(task):
	running_child = null

func child_fail(task):
	running_child = null

func run():
	if running_child:
		running_child.run()
	else:
		if current_child_index >= 0 and current_child_index < get_child_count():
			if random_children != null:
				var children = get_bt_children()
				var current_child = get_child(current_child_index)
				var current = children.find(current_child) 
				var last = children.size()-1
				if current < last:
					var other_child_index = randi() % (last - current + 1) + current
					# swap
					var temp = random_children[current]
					random_children[current] = random_children[other_child_index]
					random_children[other_child_index] = temp
					
				running_child = random_children[current]
			else:
				running_child = get_child(current_child_index)
			running_child.parent = self
			running_child.tree = tree
			running_child.start()
			if not running_child.check_guard(self):
				running_child.fail()
			else:
				running_child.run()

func start():
	running_child = null
	current_child_index = 0
	if get_children().size() <= 0:
		printerr('The composite single node has no child!')
		return
	if not get_child(current_child_index) is BTNode:
		var c = get_next_child()
		if c:
			current_child_index = c.get_index()
		else:
			printerr('The composite single node has no BTNode child!')
	.start()

func cancel_running_children(start_index):
	.cancel_running_children(start_index)
	running_child = null

func reset():
	.reset()
	current_child_index = 0
	running_child = null
	random_children = null

func create_random_children():
	var temp = []
	for child in get_children():
		if child.has_method('_Class_Type_BTNode_'):
			temp.append(child)
	return temp

func get_next_child():
	var next = current_child_index + 1
	if next >= get_child_count():
		return false
	while next < get_child_count() and not get_child(next).has_method('_Class_Type_BTNode_'):
		next += 1
	if next < get_child_count():
		return get_child(next)
	return null

