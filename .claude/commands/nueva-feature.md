---
description: Crea el andamiaje de una feature nueva siguiendo la arquitectura feature-first del proyecto
---

Crea una nueva feature llamada `$ARGUMENTS` siguiendo las convenciones del proyecto.

Pasos:
1. Consulta la skill `ui-conventions` para la estructura de carpetas.
2. Crea `lib/features/$ARGUMENTS/` con las subcarpetas `presentation/`, `domain/`
   y `data/`.
3. Crea los ficheros base mínimos (una pantalla placeholder, un provider de
   Riverpod vacío, un repositorio).
4. Si la feature toca la base de datos, consulta la skill `supabase-schema` antes.
5. NO añadas dependencias nuevas sin preguntarme.
6. Al terminar, ejecuta `flutter analyze` y resume qué has creado.
