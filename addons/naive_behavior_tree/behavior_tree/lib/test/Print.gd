tool
extends BTAction

export(String) var msg:String

#----- Methods -----
func execute():
	print(msg)
	return SUCCEEDED
