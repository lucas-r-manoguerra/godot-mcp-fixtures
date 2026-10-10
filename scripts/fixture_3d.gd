extends Node3D
## Raíz del fixture 3D para la verificación de viewport (foco y cámara).

func _mcp_state() -> Dictionary:
	return {
		"fixture": "3d",
		"child_count": get_child_count(),
		"version": 1,
	}
