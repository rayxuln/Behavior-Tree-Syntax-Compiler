tool
extends BTComposite
class_name BTCompositeDynamicGuardSelector

# 动态条件选择器
# 开始时按顺序判断子节点的条件是否成立
# 只运行成立的某一个子节点
# 若所有节点的条件都不成立，则失败

# Dynamic Guard Selector
# Choose a child that pass guard check to run in order.
# Only run one child at a time.
# If all child guard check fail, it fail.

var running_child:BTNode

#----- Methods -----
func child_running(running_task, reporter):
	running_child = running_task
	running()

func child_success(task):
	running_child = null
	success()

func child_fail(task):
	running_child = null
	fail()

func run():
	var child_to_run:BTNode = null
	for child in get_children():
		if child.has_method('_Class_Type_BTNode_'):
			if child.check_guard(self):
				child_to_run = child
				break
	
	if running_child and running_child != child_to_run:
		running_child.cancel()
		running_child = null
	
	if child_to_run == null:
		fail()
	else:
		if running_child == null:
			running_child = child_to_run
			running_child.parent = self
			running_child.tree = tree
			running_child.start()
		running_child.run()

func reset():
	.reset()
	running_child = null

func cancel():
	.cancel()
	running_child = null
