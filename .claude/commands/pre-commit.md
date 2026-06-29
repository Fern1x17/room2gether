---
description: Revisa el estado del proyecto antes de hacer commit
---

Prepara el proyecto para un commit limpio:

1. Ejecuta `dart format .`
2. Ejecuta `flutter analyze` y arregla los warnings que aparezcan.
3. Ejecuta `flutter test` y asegúrate de que pasa en verde.
4. Comprueba que no hay claves API, secretos ni ficheros `.env` a punto de
   subirse (revisa `git status`).
5. Resume los cambios y propón un mensaje de commit descriptivo en inglés.

NO hagas el commit ni el push tú; solo prepáralo y muéstrame el resumen.
