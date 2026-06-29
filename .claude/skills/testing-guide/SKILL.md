---
name: testing-guide
description: Guía de cómo escribir y organizar tests en este proyecto Flutter. Úsala SIEMPRE que escribas, modifiques o ejecutes tests.
---

# Guía de testing

## Filosofía (proyecto en solitario)

No hace falta cobertura del 100%. Prioriza tests donde el coste de un bug es alto:
lógica de negocio, repositorios, validaciones, y los flujos de auth y pagos.
La UI trivial no necesita test exhaustivo.

## Tipos de test y cuándo usarlos

- **Unit tests:** lógica pura, modelos, validaciones, providers. La mayoría de tus
  tests deben ser de este tipo (rápidos y baratos).
- **Widget tests:** pantallas con lógica de interacción no trivial (formularios,
  estados de carga/error).
- **Integration tests:** flujos críticos completos (registro → crear perfil →
  publicar). Pocos pero importantes.

## Organización

- Los tests viven en `test/`, replicando la estructura de `lib/`.
- Nombra los ficheros `<algo>_test.dart`.
- Usa `group()` para agrupar y `test()`/`testWidgets()` con descripciones claras
  en español.

## Reglas

- Mockea Supabase y servicios externos; no pegues a la BD real en unit/widget tests.
- Cada test debe ser independiente (no dependas del orden de ejecución).
- Antes de cerrar una tarea: `flutter test` debe pasar en verde.
- Si arreglas un bug, añade primero un test que lo reproduzca.

## Ejemplo de estructura

```dart
group('Validación de presupuesto', () {
  test('rechaza presupuesto mínimo mayor que el máximo', () {
    // ...
  });
  test('acepta un rango válido', () {
    // ...
  });
});
```
