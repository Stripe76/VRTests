extends Node

@export var pages : Dictionary

func set_main_panel(page):
	for n in $MainPanel.get_children():
		$MainPanel.remove_child(n)

	var node = pages[page]
	if node:
		$MainPanel.add_child(node)
	else:
		push_warning("UIViewports page node is null")
