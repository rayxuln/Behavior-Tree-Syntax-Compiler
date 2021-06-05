extends BTNode
class_name BTAction


#----- Abstract Methods -----
# must return status
func execute():
	print('This is a empty action.')
	return SUCCEEDED

#----- Final Methods -----
func run():
	var res = execute()
	if res == null:
		printerr('The execute function must return a status value!')
	match res:
		SUCCEEDED:
			success()
		FAILED:
			fail()
		RUNNING:
			running()
		_:
			printerr('The result of execute function is illegal!')
