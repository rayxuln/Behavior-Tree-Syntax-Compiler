extends Reference


#=====| How to use? |=====
# 1. var ref = CaptureFuncObject.new({capture values}, ref obj, ref func)
# 2. func ref_func(arg1, arg2, ...)
#    func ref_func(arg1, arg2, ..., data) # data contains the caputre values
# 3. ref.call_func([arg1, arg2, ...])

var data:Dictionary

var the_obj:Object
var the_func:String

func _init(d:Dictionary, obj:Object, f:String, weak:bool=false) -> void:
	data = d
	if weak:
		the_obj = weakref(obj)
	else:
		the_obj = obj
	the_func = f

func call_func(args:Array = []):
	if is_valid():
		var obj = the_obj.get_ref() if (the_obj is WeakRef) else the_obj
		if obj.has_method('_ClassType_LambdaFuncObject_'):
			obj.callv(the_func, [args + data.values()])
		else:
			if not data.empty():
				args.append(data)
			obj.callv(the_func, args)
	else:
		printerr('%s is invalid to call func: %s' % [the_obj, the_func])

func is_valid():
	if the_obj is WeakRef:
		return is_instance_valid(the_obj.get_ref())
	return is_instance_valid(the_obj)

func set_data(d):
	data = d

func _ClassType_CaptureFuncObject_():
	pass
