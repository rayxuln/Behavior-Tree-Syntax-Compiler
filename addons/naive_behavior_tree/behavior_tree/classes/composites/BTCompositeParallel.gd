tool
extends BTComposite
class_name BTCompositeParallel

enum Policy {
	SEQUENCE, # 只要有一个子节点失败，则并行节点失败；当所有子节点成功时，并行节点成功
	# As long as one child fail, it fail.
	# When all child success, it success.
	SELECTOR # 只要有一个子节点成功，则并行节点成功；只有所有节点失败，并行节点才失败
	# As long as one child success, it success.
	# Only all child fail, it fail.
}

enum Orchestrator {
	Resume, # 子节点会每帧都开始或者继续运行
					# 当一个子节点成功后完全不会等待其他子节点
	# Resume children every frame.
	Join # 子节点会执行到成功或者失败，子节点会在并行节点成功或者失败后才会重新执行
			 # 例如：假设有一个子节点为定时器节点，等待1秒钟，若其他子节点在1秒内都执行成功了，则需要等待该定时器，直到1秒结束
	# Wait for all child fail/success to fail/success.
}

export(Policy) var policy
export(Orchestrator) var orchestrator

var no_running_tasks:bool = true
var last_result
var current_child_index:int

#----- Methods -----
func run():
	match orchestrator:
		Orchestrator.Resume:
			no_running_tasks = true
			last_result = null
			for child in get_children():
				if child.has_method('_Class_Type_BTNode_'):
					if child.status == RUNNING:
						child.run()
					else:
						child.parent = self
						child.tree = tree
						child.start()
						if child.check_guard(self):
							child.run()
						else:
							child.fail()
					
					if last_result != null:
						cancel_running_children(current_child_index+1 if no_running_tasks else 0)
						if last_result:
							success()
						else:
							fail()
						return
			running()
		Orchestrator.Join:
			no_running_tasks = true
			last_result = null
			for child in get_children():
				if child.has_method('_Class_Type_BTNode_'):
					match child.status:
						RUNNING:
							child.run()
						SUCCEEDED, FAILED:
							pass
						_:
							child.parent = self
							child.tree = tree
							child.start()
							if child.check_guard(self):
								child.run()
							else:
								child.fail()
					
					if last_result != null:
						cancel_running_children(current_child_index + 1 if no_running_tasks else 0)
						reset_all_children()
						if last_result:
							success()
						else:
							fail()
						return
			running()

func child_running(running_task, reporter):
	no_running_tasks = false

func child_success(task):
	match policy:
		Policy.SEQUENCE:
			match orchestrator:
				Orchestrator.Resume:
					last_result = null
					if no_running_tasks and get_child(current_child_index) == get_last_child():
						last_result = true
				Orchestrator.Join:
					last_result = null
					if no_running_tasks and get_last_child().status == SUCCEEDED:
						last_result = true
		Policy.SELECTOR:
			last_result = true

func child_fail(task):
	match policy:
		Policy.SEQUENCE:
			last_result = false
		Policy.SELECTOR:
			last_result = null
			if no_running_tasks and get_child(current_child_index) == get_last_child():
				last_result = false

func reset():
	.reset()
	no_running_tasks = true

func reset_all_children():
	for child in get_children():
		if child.has_method('_Class_Type_BTNode_'):
			child.reset()


