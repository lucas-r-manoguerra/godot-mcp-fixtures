extends Node
## Destino de la señal de prueba: expone el método on_test_ping
## para las verificaciones de connect/disconnect/trace.

var received: Array = []
var receive_count: int = 0

func on_test_ping(arg1: String, arg2: int) -> void:
	received.append([arg1, arg2])
	receive_count += 1
