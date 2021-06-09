extends BTAction

export(String) var msg:String = ''
export(String) var n:String = ''


#----- Methods -----
func execute():
	tree.agent.get_node(n).text = msg
	return SUCCEEDED
