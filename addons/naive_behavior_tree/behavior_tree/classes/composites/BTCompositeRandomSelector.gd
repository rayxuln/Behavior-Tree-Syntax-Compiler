tool
extends BTCompositeSelector
class_name BTCompositeRandomSelector

#----- Methods -----
func start():
	.start()
	if random_children == null:
		random_children = create_random_children()
