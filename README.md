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

## Live MCP loop (opencode ↔ server ↔ Godot)

Circuito en vivo: el cliente MCP (opencode) habla con
`godot-mcp-server` por stdio/HTTP, y el server reenvía al addon
`godot_mcp` (submódulo en `addons/godot_mcp`, pineado en `e443b0c`)
que corre dentro del editor.

### Arranque

1. Abrir este proyecto en el editor de Godot 4.7 con el plugin
   "Godot MCP" habilitado (Proyecto → Plugins; queda registrado en
   `project.godot` bajo `[editor_plugins]`).
2. Al iniciar, el addon escribe un token de sesión en el registro
   del editor. Copiarlo de la línea:
   `MCP session token (send as first {command:auth} message): <token>`
3. Exportarlo y levantar el server (compilado desde
   `godot-mcp-server`, sin publicar en npm):

   ```sh
   export GODOT_MCP_TOKEN="<token-del-editor>"
   # stdio (por defecto)
   node /ruta/a/godot-mcp-server/dist/cli.js
   # o HTTP en 127.0.0.1:3000
   node /ruta/a/godot-mcp-server/dist/cli.js --http
   ```

   Registro en opencode (`opencode.json` del proyecto, server local):

   ```json
   {
     "mcp": {
       "godot-mcp-server": {
         "type": "local",
         "command": ["node", "/ruta/a/godot-mcp-server/dist/cli.js"],
         "environment": { "GODOT_MCP_TOKEN": "<token-del-editor>" },
         "enabled": true
       }
     }
   }
   ```

### Smoke test mínimo

Con el editor abierto en `scenes_2d/fixture_2d.tscn` (sin ejecutar):

1. `server_status` (handshake): responde con versión del server,
   proyecto y estado del puente WS. Confirma que el server ve al
   addon autenticado.
2. `class_list`: devuelve el catálogo de clases del proyecto.
   Confirma introspección de solo lectura.
3. `create_node` (`class_name: "Node2D"`, escena fixture abierta):
   crea el nodo en la escena del editor. Confirma escritura hacia
   el editor.
4. `capture_editor_screenshot`: devuelve imagen del editor.
   Confirma el canal de vuelta (binario del editor al cliente).

### Qué observar en cada dirección

- opencode → Godot: cada llamada MCP aparece como comando en el
  registro del addon; `create_node` deja el nodo visible en el
  árbol de la escena abierta (deshacer con Ctrl+Z lo elimina).
- Godot → opencode: las respuestas viajan por el puente WS al
  server y de ahí al cliente; `capture_editor_screenshot` trae
  píxeles reales del editor, y `server_status` refleja cambios
  (escena abierta, estado de ejecución) sin reiniciar el server.

### Notas

- El primer `godot --headless --import` con el plugin habilitado
  agrega automáticamente el autoload `MCPGameBridge` y la sección
  `[godot_mcp]` en `project.godot`; ambos cambios quedan
  commiteados y son el único ajuste extra necesario.
- El token rota en cada arranque del editor: repetir los pasos 2
  y 3 al reabrir Godot.
