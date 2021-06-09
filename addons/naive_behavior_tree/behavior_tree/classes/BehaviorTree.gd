tool
extends BTNode
class_name BehaviorTree, '../../icon.svg'

signal task_started(task)
signal task_ended(task)

export(NodePath) var agent_path
var agent

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
	if Engine.editor_hint:
		return
	root = get_node(root_path)
	tree = self
	
	agent = get_node_or_null(agent_path)

	
func _process(delta: float) -> void:
	if Engine.editor_hint:
		return
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

	
	
	
	
	
	
