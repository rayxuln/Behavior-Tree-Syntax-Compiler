tool
extends BTAction
class_name BTActionTimer

var start_time:float
export(float) var wait:float = 1 #sec

#----- Methods -----
func start():
	start_time = OS.get_ticks_msec()
	.start()
	

func execute():
	return RUNNING if OS.get_ticks_msec() - start_time < wait * 1000 else SUCCEEDED

func reset():
	start_time = 0
	.reset()
