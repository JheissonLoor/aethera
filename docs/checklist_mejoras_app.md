# Checklist de mejoras de app (previo a commit final)

## 1) Diseno y UX premium
- [x] Redisenar barra inferior de Universe (menos saturada, acciones primarias + menu mas)
- [x] Ajustar jerarquia visual del TopBar y tarjetas secundarias de Universe
- [x] Unificar espaciados y densidad visual en Universe (zonas de aire y alineacion)
- [x] Mejorar composicion visual de Profile (cards, ring, bloques de accion)
- [x] Pulir Auth para que se vea mas premium (tipografia, ritmo vertical, microdetalles)
- [x] Pulir Onboarding (coherencia visual, copy y transiciones)

## 2) Motion system
- [x] Introducir menu de acciones secundarias con transicion dedicada
- [x] Definir transiciones por tipo (pantalla, sheet, estado, feedback)
- [x] Unificar duraciones y curvas en componentes clave
- [x] Revisar haptics para que acompanen las acciones principales

## 3) Localizacion y limpieza visual
- [x] Revisar textos visibles para tono consistente en espanol
- [x] Corregir cualquier texto/simbolo roto que aparezca en pantallas clave
- [x] Verificar labels semanticos en botones de accion principal

## 4) Calidad tecnica
- [x] flutter analyze
- [x] flutter test
- [x] flutter build appbundle --release
- [x] Revisar CI localmente para evitar romper el pipeline

## Estado actual
- Listo para commit final conjunto de mejoras de producto/calidad/diseno.
