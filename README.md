# GodotMCPFixtures

Fixtures en vivo para la verificación de las 16 herramientas faltantes
(`gap-tools`) entre `godot-mcp-server` y el addon de Godot. Proyecto
Godot 4 mínimo (línea base 4.7.2, compatible con 4.5+; renderizador
GL Compatibility para ejecución headless). Sin assets de terceros.

## Estructura

```text
scenes_2d/fixture_2d.tscn   # FixtureRoot/Alpha, Beta, SampleControl + señales
scenes_3d/fixture_3d.tscn   # FocusRoot/FocusBox (MeshInstance3D) + TargetMarker
scripts/                    # fixture_2d, state_probe_a, ping_emitter,
                            # ping_target, fixture_3d, uid_probe_data
assets/sample.txt           # sonda de importación para import_asset
assets/uid_probe.tres       # recurso con UID registrado para uid_resolve
                            # (uid://tskoqg74gcp0)
assets/bulk/                # 250 ficheros generados para la paginación
                            # de list_assets (ver tools/gen_bulk_assets.sh)
tools/verify_fixtures.gd    # verificación autosuficiente (ver abajo)
tools/gen_bulk_assets.sh    # regenera assets/bulk
```

## Nodos con `_mcp_state()`

Tres nodos exponen `func _mcp_state() -> Dictionary` con valores
escalares para `runtime_state`: `FixtureRoot` (fixture 2D),
`Alpha` (sonda con posición) y `FocusRoot` (fixture 3D).

## Señales

`PingEmitter` emite `test_ping(arg1: String, arg2: int)` y `PingTarget`
expone `on_test_ping(arg1, arg2)`. La escena los deja SIN conectar:
cada verificación (`connect_signal`, `disconnect_signal`,
`trace_signal`) establece su propia conexión. `ping_now()` emite un
evento bajo demanda.

## Posiciones conocidas (fixture 3D)

- `FocusBox.global_position == Vector3(4, 2, -6)` (caja de 2×2×2).
- `TargetMarker.global_position == Vector3(10, 0, 0)`.

Base para la matemática de foco de `set_3d_viewport`.

## Procedimiento: editor en reposo (idle)

1. Abrir este proyecto en el editor de Godot.
2. Abrir `scenes_2d/fixture_2d.tscn` o `scenes_3d/fixture_3d.tscn`.
3. NO ejecutar la escena. El juego no corre (`is_playing_scene() == false`).
4. Casos esperados: `trace_signal` responde `NOT_RUNNING`; el resto de
   comandos de escena operan sobre la escena abierta en el editor.

## Procedimiento: juego en ejecución

1. Ejecutar la escena (`F6` sobre el fixture o proyecto en marcha).
2. Con `is_playing_scene() == true`, `trace_signal` recoge eventos de
   `test_ping` durante la ventana solicitada; `ping_now()` genera
   eventos bajo demanda.
3. Detener la ejecución al terminar para volver al caso idle.

## Verificación

```sh
godot --headless --import
godot --headless --script res://tools/verify_fixtures.gd
for f in scripts/*.gd tools/verify_fixtures.gd; do
  godot --headless --check-only --script "res://$f"
done
```

`.godot/` se excluye del repositorio por diseño: los recorridos de
`list_assets` deben ignorarlo explícitamente.
