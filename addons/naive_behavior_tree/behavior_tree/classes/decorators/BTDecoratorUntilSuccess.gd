tool
extends BTLoopDecorator
class_name BTDecoratorUntilSuccess


#----- Methods -----
func child_success(task):
	success()
	loop = false

func child_fail(task):
	loop = true
