tool
extends BTLoopDecorator
class_name BTDecoratorUntilFail

#----- Methods -----
func child_success(task):
	loop = true

func child_fail(task):
	success()
	loop = false
