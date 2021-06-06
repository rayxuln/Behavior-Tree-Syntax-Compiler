tool
extends BTCompositeSequence
class_name BTCompositeRandomSequence


#----- Methods -----
func start():
	.start()
	if random_children == null:
		random_children = create_random_children()
