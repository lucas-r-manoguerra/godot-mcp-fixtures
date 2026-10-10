extends SceneTree
## Verificación autosuficiente de los fixtures (puerta de entrada viva).
##
## Uso: godot --headless --script res://tools/verify_fixtures.gd
## Sale con código 0 si todo es válido, 1 en caso contrario.

var _failures: Array = []

func _initialize() -> void:
	_check_scene("res://scenes_2d/fixture_2d.tscn", "FixtureRoot")
	_check_scene("res://scenes_3d/fixture_3d.tscn", "FocusRoot")
	_check_uid()
	_check_signals()
	await _check_mcp_state()
	if _failures.is_empty():
		print("VERIFY_FIXTURES: OK")
	else:
		for failure: String in _failures:
			printerr("VERIFY_FIXTURES FALLO: " + failure)
	quit(1 if not _failures.is_empty() else 0)

func _fail(message: String) -> void:
	_failures.append(message)

func _check_scene(path: String, expected_root: String) -> void:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null or not packed.can_instantiate():
		_fail("no se puede instanciar " + path)
		return
	var instance: Node = packed.instantiate()
	if instance.name != expected_root:
		_fail(path + ": raíz '" + instance.name + "' != '" + expected_root + "'")
	instance.queue_free()

func _check_uid() -> void:
	var uid: int = ResourceLoader.get_resource_uid("res://assets/uid_probe.tres")
	if uid == -1 or not ResourceUID.has_id(uid):
		_fail("uid_probe.tres sin UID registrado")
		return
	var probe: Resource = load("res://assets/uid_probe.tres") as Resource
	if probe == null or String(probe.get("label")) != "sonda-uid":
		_fail("uid_probe.tres no carga el recurso esperado")

func _check_signals() -> void:
	var packed: PackedScene = load("res://scenes_2d/fixture_2d.tscn") as PackedScene
	var instance: Node = packed.instantiate()
	var emitter: Node = instance.get_node("PingEmitter")
	var target: Node = instance.get_node("PingTarget")
	var found := false
	for info: Dictionary in emitter.get_signal_list():
		if String(info.get("name", "")) == "test_ping":
			found = true
	if not found:
		_fail("PingEmitter no expone test_ping")
	if not target.has_method("on_test_ping"):
		_fail("PingTarget no expone on_test_ping")
	emitter.connect("test_ping", Callable(target, "on_test_ping"))
	emitter.call("ping_now", "verificacion", 7)
	if int(target.get("receive_count")) != 1:
		_fail("el enlace test_ping -> on_test_ping no entregó el evento")
	emitter.disconnect("test_ping", Callable(target, "on_test_ping"))
	instance.queue_free()

func _check_mcp_state() -> void:
	var packed_2d: PackedScene = load("res://scenes_2d/fixture_2d.tscn") as PackedScene
	var root_2d: Node = packed_2d.instantiate()
	_expect_state(root_2d, "FixtureRoot._mcp_state")
	_expect_state(root_2d.get_node("Alpha"), "Alpha._mcp_state")
	root_2d.queue_free()
	var packed_3d: PackedScene = load("res://scenes_3d/fixture_3d.tscn") as PackedScene
	var root_3d: Node = packed_3d.instantiate()
	get_root().add_child(root_3d)
	# Los nodos entran al árbol en el siguiente frame; sin esta espera
	# global_position no resuelve en ejecución headless con --script.
	await process_frame
	_expect_state(root_3d, "FocusRoot._mcp_state")
	var box: Node3D = root_3d.get_node("FocusBox") as Node3D
	if box == null or not box.global_position.is_equal_approx(Vector3(4, 2, -6)):
		_fail("FocusBox fuera de la posición documentada (4, 2, -6)")
	var marker: Node3D = root_3d.get_node("TargetMarker") as Node3D
	if marker == null or not marker.global_position.is_equal_approx(Vector3(10, 0, 0)):
		_fail("TargetMarker fuera de la posición documentada (10, 0, 0)")
	root_3d.queue_free()

func _expect_state(node: Node, label: String) -> void:
	if not node.has_method("_mcp_state"):
		_fail(label + " ausente")
		return
	var state: Dictionary = node.call("_mcp_state")
	if state.is_empty():
		_fail(label + " devolvió un diccionario vacío")
