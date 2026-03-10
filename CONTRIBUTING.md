# Guía de Contribución

Gracias por tu interés en mejorar Aethera.

## Requisitos antes de abrir PR

1. Tener Flutter 3.x instalado.
2. Ejecutar dependencias:

```bash
flutter pub get
```

3. Validar calidad local:

```bash
flutter analyze
flutter test
```

## Flujo recomendado

1. Crea una rama descriptiva desde `main`.
2. Haz cambios pequeños y enfocados.
3. Escribe commits claros (convencionales si es posible).
4. Abre un Pull Request explicando:
   - Problema que resuelve.
   - Solución aplicada.
   - Riesgos o impactos.
   - Evidencia visual (capturas/GIF) si toca UI.

## Convenciones del proyecto

- Mantén la arquitectura por dominio: `core`, `features`, `shared`.
- Evita mezclar cambios de refactor + feature + fix en un solo PR.
- Prioriza nombres explícitos y código legible sobre atajos.
- No subas secretos ni archivos locales de Firebase.

## Seguridad

No se aceptan commits con credenciales, tokens o claves API.
Si detectas una exposición accidental, repórtala y revoca/rota la clave inmediatamente.
