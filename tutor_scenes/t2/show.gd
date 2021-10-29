extends BTAction

export(String) var s:String = ''

#----- Methods -----
func execute():
	tree.agent.get_node('Label').text = s
	return SUCCEEDED
