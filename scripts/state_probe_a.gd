extends Node2D
## Sonda de estado sobre el nodo Alpha del fixture 2D.

@export var probe_id: String = "alpha"

func _mcp_state() -> Dictionary:
	return {
		"probe": probe_id,
		"x": position.x,
		"y": position.y,
	}
