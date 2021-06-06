tool
extends BTDecorator
class_name BTLoopDecorator

var loop:bool

#----- Methods -----
func condition():
	return loop

func run():
	loop = true
	while condition():
		if get_bt_child().status == RUNNING:
			child.run()
		else:
			child.parent = self
			child.tree = tree
			child.start()
			if child.check_guard(self):
				child.run()
			else:
				child.fail()

func child_running(running_task, reporter):
	.child_running(running_task, reporter)
	loop = false
