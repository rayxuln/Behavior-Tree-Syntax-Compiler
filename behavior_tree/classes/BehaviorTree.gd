extends BTNode
class_name BehaviorTree


export(NodePath) var root_path
var root:BTNode = null

class GuardEvaluator:
	extends BTNode
	
	func run():
		pass
	
	func child_success(task):
		pass
	
	func child_fail(task):
		pass
	
	func child_running(running_task, reporter):
		pass

var guard_evaluator:GuardEvaluator

func _enter_tree() -> void:
	guard_evaluator = GuardEvaluator.new()
	guard_evaluator.tree = tree

func _exit_tree() -> void:
	guard_evaluator.free()
	guard_evaluator = null

func _ready() -> void:
	root = get_node(root_path)
	tree = self
	
func _process(delta: float) -> void:
	step()
#----- Methods -----
func child_running(running_task, reporter):
	running()

func child_fail(task):
	fail()

func child_success(task):
	success()

func step():
	if root.status == RUNNING:
		root.run()
	else:
		root.parent = self
		root.tree = self
		root.start()
		if root.check_guard(self):
			root.run()
		else:
			root.fail()

func run():
	pass

func reset():
	.reset()
	tree = self
#----- Signals -----
