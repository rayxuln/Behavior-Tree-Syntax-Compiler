tool
extends BTAction

export(float) var wait:float = 1

#----- Methods -----
func execute():
	print('wait for 1 sec')
	yield(get_tree().create_timer(wait), "timeout")
	print('wait for 2 sec')
	yield(get_tree().create_timer(2), "timeout")
	print('wait for 3 sec')
	yield(get_tree().create_timer(3), "timeout")
	print('done.')
	return SUCCEEDED
