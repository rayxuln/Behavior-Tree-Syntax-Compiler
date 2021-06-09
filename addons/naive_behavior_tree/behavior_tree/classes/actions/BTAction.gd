tool
extends BTNode
class_name BTAction

var last_func_state:GDScriptFunctionState
var is_finally_done:bool

#----- Abstract Methods -----
# In order to implement the function you want, you need to override this function.
# must return status
# support yiled statement
func execute():
	print('This is a empty action.')
	return SUCCEEDED

#----- Final Methods -----
func start():
	.start()
	last_func_state = null
	is_finally_done = false

func run():
	var res = null
	if last_func_state == null:
		res = execute()
		if res == null:
			printerr('The execute function must return a status value!')
		if res is GDScriptFunctionState:
			if res.is_valid():
				wait_func_state_to_complete(res)
				running()
			else:
				fail()
			return
		match_res(res)
	else:
		if not is_finally_done:
			running()
		else:
			last_func_state = null
			is_finally_done = false

func match_res(res):
	match res:
			SUCCEEDED:
				success()
			FAILED:
				fail()
			RUNNING:
				running()
			_:
				printerr('The result of execute function is illegal!')

func wait_func_state_to_complete(func_state):
	last_func_state = func_state
	var res = yield(func_state, "completed")
	if res is GDScriptFunctionState:
		if res.is_valid():
			wait_func_state_to_complete(res)
		else:
			is_finally_done = true
			fail()
	else:
		is_finally_done = true
		match_res(res)



