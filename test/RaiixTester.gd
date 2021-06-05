extends Reference
class_name RaiixTester

func get_name():
	return 'Unkown Test'

# call methods that start with '_test_'
func run_tests():
	print(">=====| Runing Tests of %s |=====<" % (get_name()))
	var methods = []
	for m in get_method_list():
		if m.name.find("_test_") != -1:
			methods.append(m.name)
	print("Found total test num: " + str(methods.size()))
	var cnt = 0
	for m in methods:
		print("> Testing " + m + "[%d/%d]" % [cnt+1, methods.size()])
		call(m)
		cnt += 1
	print("Done!")
