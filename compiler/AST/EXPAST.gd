extends Reference



#----- Sub Classes -----
class EXPNode:
	extends Reference
	
	func execute(agent):
		pass
	
	

class BranchNode:
	extends EXPNode
	
	var op # token
	
	var children:Array # [EXPNode]
	
	func _init() -> void:
		children = []
	

class LeafNode:
	extends EXPNode
	
	var token
	



