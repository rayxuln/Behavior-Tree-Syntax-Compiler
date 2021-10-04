tool
extends BTAction
class_name BTActionRandomTimer

var start_time:float
var wait:float = 1 #sec

export(float) var min_wait:float = 0 #sec
export(float) var max_wait:float = 1 #sec

#----- Methods -----
func start():
	start_time = OS.get_ticks_msec()
	wait = rand_range(min_wait, max_wait)
	.start()
	

func execute():
	return RUNNING if OS.get_ticks_msec() - start_time < wait * 1000 else SUCCEEDED

func reset():
	start_time = 0
	.reset()
