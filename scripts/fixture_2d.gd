extends Node
## Raíz del fixture 2D para la verificación gap-tools.
##
## Expone nodos nombrados para create/duplicate/delete y un estado
## escalar legible vía runtime_state.

func _mcp_state() -> Dictionary:
	return {
		"fixture": "2d",
		"child_count": get_child_count(),
		"version": 1,
	}
