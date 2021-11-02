extends Reference

signal request_put_var(data)

var request_id_count := -1

var pandding_request_map_list := {}

enum {
	REQ,
	RES,
	SUB, # for event
}

#----- APIs -----

#----- Methods -----
func _init() -> void:
	var event_list = get_event_name_list()
	for e in event_list:
		add_user_signal(e, [TYPE_DICTIONARY])

func get_api_name(name:String) -> String:
	return 'api_%s' % name

func get_event_name_list():
	return [
		'something_changed',
	]

func gen_event(name:String, data = null):
	return {
		'name': name,
		'data': data,
	}

func boardcast_event(name:String, data = null):
	var event = gen_event(name, data)
	emit_signal('request_put_var', gen_sub(event))

func call_api(name:String, args := [], callback = null):
	var req:Dictionary = gen_req(name, callback, args)
	if not pandding_request_map_list.has(name):
		pandding_request_map_list[name] = []
	pandding_request_map_list[name].append(req)
	req = req.duplicate()
	req.erase('callback')
	emit_signal('request_put_var', req)

func get_new_request_id():
	request_id_count += 1
	return request_id_count

func gen_req(name:String, callback = null, args := []):
	return {
		'id': get_new_request_id(),
		'name': name,
		'type': REQ,
		'args': args,
		'callback': callback,
	}

func gen_res(req:Dictionary, data = null):
	return {
		'id': req.id,
		'name': req.name,
		'type': RES,
		'data': data,
	}

func gen_sub(event):
	return {
		'type': SUB,
		'event': event,
	}

func on_recieve_data(peer, data):
	if not data is Dictionary:
		return
	if not data.has('type'):
		return
	match data.type:
		REQ:
			var func_name = get_api_name(data.name)
			if not has_method(func_name):
				printerr('api func %s does not exist.' % func_name)
				return
			var res_data = callv(func_name, data.args)
			var res = gen_res(data, res_data)
			emit_signal('request_put_var', res)
		RES:
			var name = data.name
			if pandding_request_map_list.has(name):
				for req in pandding_request_map_list[name]:
					if req.id == data.id:
						if req.callback:
							req.callback.call_func([data.data])
				pandding_request_map_list[name].clear()
		SUB:
			var event = data.event
			emit_signal(event.name, event)

