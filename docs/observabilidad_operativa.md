# Observabilidad Operativa (Crashlytics + Analytics)

## Objetivo
Tener visibilidad operativa real en producción con 4 KPI clave:

1. `crash_free_users`
2. fallos de sincronización (`kpi_sync_failure`)
3. drops de cola (`kpi_queue_drop`)
4. fallos de arranque (`kpi_startup_failure`)

## Eventos KPI instrumentados

### Arranque
- `startup_ready`: app inició correctamente.
- `startup_failed`: el arranque falló (incluye `timeout` y `attempt`).
- `startup_retry_tapped`: usuario tocó "Reintentar" en pantalla de recuperación.
- `startup_recovered`: inicio exitoso luego de uno o más intentos.
- `kpi_startup_failure`: evento KPI para alertas de arranque.

### Sincronización offline/online
- `sync_action_queued`: acción enviada a cola local.
- `sync_action_sent`: acción enviada en línea.
- `sync_action_requeued`: acción reencolada tras fallo de red.
- `sync_action_dropped`: acción descartada por error permanente.
- `sync_queue_flushed`: resumen de flush (`attempted`, `success`, `failed_transient`, `dropped`, `remaining`).
- `kpi_sync_failure`: evento KPI agregado de fallos de sincronización.
- `kpi_queue_drop`: evento KPI agregado de drops (`drop_reason`: `queue_overflow` o `permanent_error`).

## Dashboard recomendado

### 1) Crashlytics (Firebase Console > Crashlytics)
- Widget: `Crash-free users` (24h, 7d, 30d).
- Widget: `Fatal issues` por versión (`app_version`).
- Widget: `Non-fatal` por razón (`startup`, `sync`, `notification`, `music`).

### 2) Analytics (Firebase Console > Analytics > Events/Explore)
- Panel `Inicio`:
  - Conteo `startup_ready`
  - Conteo `kpi_startup_failure`
  - Conteo `startup_retry_tapped`
  - Conteo `startup_recovered`
- Panel `Sync`:
  - Conteo `kpi_sync_failure`
  - Conteo `kpi_queue_drop`
  - Suma de `failed` y `dropped` (desde parámetros de evento)
  - Suma de `remaining` para detectar acumulación de cola

## Alertas sugeridas

### 1) Estabilidad de app (P1)
- Fuente: Crashlytics alertas nativas.
- Regla: `Crash-free users < 99.5%` en 1 hora.
- Acción: notificar Slack/Email + abrir incidente.

### 2) Fallo de arranque (P1)
- Fuente: Analytics custom insight (evento).
- Regla: `kpi_startup_failure >= 5` en 15 minutos.
- Acción: revisar último release, Firebase init, y errores de startup en Crashlytics.

### 3) Fallos de sincronización (P2)
- Fuente: Analytics custom insight.
- Regla: `kpi_sync_failure >= 10` en 15 minutos.
- Acción: revisar conectividad RTDB/Firestore, permisos y errores `sync_queue_action_failed`.

### 4) Drops de cola (P2)
- Fuente: Analytics custom insight.
- Regla: `kpi_queue_drop >= 1` en 15 minutos.
- Acción: inspeccionar `drop_reason`:
  - `queue_overflow`: usuario acumuló demasiadas acciones offline.
  - `permanent_error`: payload inválido o permisos/argumentos no válidos.

## Runbook rápido

1. Confirmar alcance: versión afectada, plataforma y ventana temporal.
2. Revisar Crashlytics: issue dominante y stacktrace.
3. Revisar Analytics: volumen de `kpi_startup_failure`, `kpi_sync_failure`, `kpi_queue_drop`.
4. Si hay `queue_overflow`, priorizar conectividad + reducción de acciones pesadas.
5. Si hay `permanent_error`, corregir payload/validaciones y desplegar hotfix.

## Archivos clave en código
- `lib/main.dart`
- `lib/features/universe/providers/universe_provider.dart`
- `lib/core/services/offline_sync_queue_service.dart`
- `lib/core/constants/telemetry_events.dart`
