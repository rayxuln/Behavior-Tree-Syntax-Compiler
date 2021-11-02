tool
extends BTNode
class_name BehaviorTree, '../../icon.svg'

signal task_started(task)
signal task_ended(task)
signal task_status_changed(task)

signal tree_active
signal tree_inactive

export var enable := true setget _on_set_enable
func _on_set_enable(v):
	if enable != v:
		if v:
			if resume_mode == ResumeMode.Reset:
				reset()
			emit_signal('tree_active')
		else:
			emit_signal('tree_inactive')
	enable = v
var ready := false
enum ResumeMode {
	Resume,
	Reset,
}
export(ResumeMode) var resume_mode = ResumeMode.Resume

export(NodePath) var agent_path
var agent

export(NodePath) var root_path
var root:BTNode = null

enum ProcessMode {
	Process,
	Physics,
}
export(ProcessMode) var process_mode = ProcessMode.Physics setget _on_set_process_mode
func _on_set_process_mode(v):
	process_mode = v
	set_process(process_mode == ProcessMode.Process)
	set_physics_process(process_mode == ProcessMode.Physics)

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
	
	ready = true
	
	_on_set_process_mode(process_mode)
	

func _notification(what: int) -> void:
	if Engine.editor_hint:
		return
	if not enable:
		return
	match what:
		NOTIFICATION_PHYSICS_PROCESS:
			if process_mode == ProcessMode.Physics:
				step()
		NOTIFICATION_PROCESS:
			if process_mode == ProcessMode.Process:
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

	
	
	
	
	
	
