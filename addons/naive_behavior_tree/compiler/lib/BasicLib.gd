tool
extends './LibBase.gd'


#----- Lib -----
func lib_sin(x):
	return sin(x)

func lib_cos(x):
	return cos(x)

func lib_rand_range(a, b):
	return rand_range(a, b)
	
func lib_randi():
	return randi()

func lib_randf():
	return randf()

func lib_randi_range(a, b):
	if a > b:
		var t = a
		a = b
		b = t
	elif a == b:
		return a
	return randi() % (b - a + 1) + a

func lib_get_ticks_msec():
	return OS.get_ticks_msec()

func lib_get_system_time_msecs():
	return OS.get_system_time_msecs()

func lib_none():
	return null

func lib_array(head, tail):
	if tail == null:
		return [head]
	return [head] + tail

func lib_choose(l):
	return l[lib_randi_range(0, l.size()-1)]



