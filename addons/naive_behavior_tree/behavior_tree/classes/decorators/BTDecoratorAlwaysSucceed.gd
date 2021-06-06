tool
extends BTDecorator
class_name BTDecoratorAlwaysSucceed

#----- Methods -----
func child_fail(task):
	child_success(task)
