tool
extends BTDecorator
class_name BTDecoratorRandom

export(float) var success_posibility:float = 0.5

#----- Methods -----
func run():
	if get_bt_child():
		.run()
	else:
		decide()

func child_fail(task):
	decide()

func child_success(task):
	decide()

func decide():
	if randf() <= success_posibility:
		success()
	else:
		fail()
