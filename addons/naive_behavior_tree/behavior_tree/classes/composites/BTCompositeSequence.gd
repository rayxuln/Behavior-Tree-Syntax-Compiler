tool
extends BTCompositeSingle
class_name BTCompositeSequence

# 顺序
# 按顺序运行子节点
# 当一个子节点运行成功后，才运行下一个节点
# 当所有子节点都运行成功后，才视为运行成功

# sequence
# Run children in order
# Only when a child success, it runs the next child.
# When all child success, it success.

#----- Methods -----
func child_success(task):
	.child_success(task)
	var next_child = get_next_child()
	if next_child:
		current_child_index = next_child.get_index()
		run()
	else:
		success()

func child_fail(task):
	.child_fail(task)
	fail()
