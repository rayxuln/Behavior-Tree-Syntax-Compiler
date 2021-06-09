tool
extends BTCompositeSingle
class_name BTCompositeSelector

# 顺序选择器
# 按顺序从子节点中选择一个节点进行运行
# 若该节点运行成功，则成功
# 若失败，则选取下一个节点来运行

# selector
# Choose one child to run in order
# If the child success, it success
# Otherwise, it chooses next child to run.

#----- Methods -----
func child_success(task):
	.child_success(task)
	success()

func child_fail(task):
	.child_fail(task)
	var next_child = get_next_child()
	if next_child:
		current_child_index = next_child.get_index()
		run()
	else:
		fail()
