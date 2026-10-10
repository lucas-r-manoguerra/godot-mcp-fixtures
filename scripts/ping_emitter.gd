extends Node
## Emisor de la señal de prueba para connect/disconnect/trace.
##
## La señal se deja SIN conectar en la escena: cada verificación
## (connect_signal, trace_signal) establece su propia conexión.

signal test_ping(arg1: String, arg2: int)

func ping_now(first: String = "hola", second: int = 42) -> void:
	test_ping.emit(first, second)
