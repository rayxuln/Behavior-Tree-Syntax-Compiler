tool
extends BTDecorator
class_name BTDecoratorAlwaysFail


#----- Methods -----
func child_success(task):
	child_fail(task)
