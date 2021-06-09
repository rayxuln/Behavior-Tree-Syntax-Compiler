extends BTAction

export(String) var obj:String = ''
export(String) var sig:String = ''


#----- Methods -----
func execute():
	yield(tree.agent.get_node(obj), sig)
	return SUCCEEDED
