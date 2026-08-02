class_name ErrorHelper

static func try(e: Error) -> void:
	if e == OK:
		return
	
	var main_tree: SceneTree = Engine.get_main_loop() as SceneTree
	var main_root: Node = main_tree.root
	
	print_debug(e)
	main_root.propagate_notification(main_root.NOTIFICATION_WM_CLOSE_REQUEST)
	main_tree.quit(e)
