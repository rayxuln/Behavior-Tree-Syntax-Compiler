tool
extends BTNode
class_name BTDecorator

var child = null

#----- Methods -----
func run():
	if get_bt_child().status == RUNNING:
		child.running()
	else:
		child.parent = self
		child.tree = tree
		child.start()
		if child.check_guard(self):
			child.run()
		else:
			child.fail()

func child_running(running_task, reporter):
	running()

func child_fail(task):
	fail()

func child_success(task):
	success()
	
func reset():
	child = null

func get_bt_child():
	if child:
		return child
	if get_child_count() == 0:
		return null
	var i = 0
	while i < get_child_count() and not get_child(i).has_method('_Class_Type_BTNode_'):
		i += 1
	child = get_child(i)
	return child
