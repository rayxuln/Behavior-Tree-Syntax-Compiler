tool
extends Node
class_name BTNode

enum {
	FRESH,
	RUNNING,
	FAILED,
	SUCCEEDED,
	CANCELLED
}

var parent:Node = null
var tree = null
export(NodePath) var guard_path
var guard:Node = null
var status = FRESH

func _ready() -> void:
	if Engine.editor_hint:
		return
	if not guard:
		guard = get_node_or_null(guard_path)

#----- Final Methods -----
func running():
	status = RUNNING
	if parent:
		parent.child_running(self, self)
	
func success():
	status = SUCCEEDED
	end()
	if parent:
		parent.child_success(self)
	
func fail():
	status = FAILED
	end()
	if parent:
		parent.child_fail(self)
	
func cancel():
	cancel_running_children(0)
	status = CANCELLED
	end()

func cancel_running_children(start_index):
	var i = start_index
	var n = get_child_count()
	while i < n:
		var child = get_child(i) as Node
		if child.has_method('_Class_Type_BTNode_'):
			if child.status == RUNNING:
				child.cancel()
		i += 1

func check_guard(_parent):
	if guard == null:
		return true
	
	if not guard.check_guard(_parent):
		return false
	
	guard.parent = _parent.tree.guard_evaluator
	guard.tree = _parent.tree
	guard.start()
	guard.run()
	
	match guard.status:
		SUCCEEDED:
			return true
		FAILED:
			return false
		_:
			printerr('Illegal guard status: %s' % str(guard.status))
			return false

func _Class_Type_BTNode_():
	pass
#----- Abstract Methods -----
func run():
	pass

func child_success(task):
	pass

func child_fail(task):
	pass

func child_running(running_task, reporter):
	pass
#----- Methods -----
func start():
	tree.emit_signal('task_started', self)

func end():
	tree.emit_signal('task_ended', self)

func reset():
	if status == RUNNING:
		cancel()
	for child in get_children():
		if child.has_method('_Class_Type_BTNode_'):
			child.reset()
	status = FRESH
	tree = null
	parent = null
