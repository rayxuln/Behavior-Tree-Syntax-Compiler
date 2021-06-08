tool
extends BTLoopDecorator
class_name BTDecoratorRepeat

export(int) var times:int

var count:int

#----- Methods -----
func start():
	count = times
	.start()

func condition():
	return loop and count != 0

func child_success(task):
	if count > 0:
		count -= 1
	if count == 0:
		.child_success(task)
		loop = false
	else:
		loop = true

func child_fail(task):
	child_success(task)

