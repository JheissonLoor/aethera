# Rollout seguro: invite_codes + reglas estrictas

Este runbook evita romper el flujo de pairing al endurecer reglas Firebase.

## Objetivo

- Migrar de lookup por `couples.where(inviteCode)` a `invite_codes/{code}`.
- Backfill de `invite_codes` para parejas abiertas antiguas.
- Publicar reglas estrictas de Firestore/RTDB/Storage con validacion de membresia.

## Prerrequisitos

- Codigo cliente actualizado (incluye [couple_service.dart](C:/CoolImport/aethera/lib/core/services/couple_service.dart) nuevo).
- `firebase-tools` autenticado con permisos de deploy.
- Credenciales admin para backfill (una de estas):
  - `GOOGLE_APPLICATION_CREDENTIALS` apuntando a service account JSON.
  - `FIREBASE_SERVICE_ACCOUNT_JSON` con JSON inline.
- `FIREBASE_PROJECT_ID` o `--project=<id>`.

## Orden recomendado (produccion)

1. Congelar deploys paralelos mientras dura la migracion.
2. Ejecutar backfill en modo simulacion (`dry-run`) y revisar salida.
3. Ejecutar backfill en modo aplicacion (`--apply`).
4. Desplegar cliente actualizado.
5. Verificar adopcion de version minima del cliente (o forzar update).
6. Desplegar reglas estrictas (Firestore, Database, Storage).
7. Ejecutar smoke test funcional.
8. Monitorear errores `permission_denied` y regresiones por al menos 24h.

## Comandos de backfill

Desde [firebase/rules](C:/CoolImport/aethera/firebase/rules):

```bash
npm ci
npm run backfill:invite-codes -- --project=<PROJECT_ID> --dry-run
npm run backfill:invite-codes -- --project=<PROJECT_ID> --apply
```

Opcionales:

- `--batch-size=500`
- `--max-generate-attempts=64`

## Que hace el script

Script: [backfill_invite_codes.cjs](C:/CoolImport/aethera/firebase/rules/scripts/backfill_invite_codes.cjs)

- Escanea `couples` abiertos (`user2Id == ''`).
- Crea `invite_codes/{code}` si falta.
- Reactiva `invite_codes/{code}` si estaba inactivo.
- Si el `inviteCode` del couple es invalido o conflictivo, genera uno nuevo unico y actualiza `couples/{id}.inviteCode`.
- Reporta resumen final con conteos y errores.

## Deploy de reglas

Desde la raiz del repo:

```bash
firebase deploy --only firestore:rules,database,storage --project <PROJECT_ID>
```

Archivos afectados:

- [firestore.rules](C:/CoolImport/aethera/firestore.rules)
- [database.rules.json](C:/CoolImport/aethera/database.rules.json)
- [storage.rules](C:/CoolImport/aethera/storage.rules)

## Smoke test post-deploy

1. Crear pareja nueva:
  - Usuario A crea universo.
  - Confirmar que se creo `invite_codes/{code}` activo.
2. Join por codigo:
  - Usuario B usa codigo y entra a la pareja.
  - Confirmar `couples/{id}.user2Id` actualizado.
  - Confirmar `invite_codes/{code}.active == false`.
3. Presence RTDB:
  - Ambos usuarios conectan.
  - Confirmar lecturas/escrituras solo entre miembros.
4. Flujo ritual:
  - Submit de respuestas y sync hold.
  - Confirmar que reglas permiten solo campos dinamicos esperados.
5. Storage:
  - Upload valido por owner en `users/{uid}/...`.
  - Confirmar rechazo en path ajeno y `contentType` invalido.

## Monitoreo recomendado

- Firestore/RTDB denied spikes.
- Errores de pairing/join en analytics.
- Crashlytics no-fatal relacionados a permisos.
- Tiempo de conversion en onboarding -> pairing -> universe.

## Rollback rapido

Si hay impacto critico:

1. Revertir reglas a la version anterior.
2. Mantener app nueva mientras se corrige (es backward-safe con `invite_codes`).
3. Corregir y volver a aplicar runbook completo.
