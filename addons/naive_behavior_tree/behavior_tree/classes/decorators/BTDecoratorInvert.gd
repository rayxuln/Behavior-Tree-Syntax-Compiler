tool
extends BTDecorator
class_name BTDecoratorInvert

#----- Methods -----
func child_success(task):
	child_fail(task)

func child_fail(task):
	child_success(task)

