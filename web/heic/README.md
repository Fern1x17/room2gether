# Decodificador HEIC (fichero de terceros, versionado a propósito)

`heic2any.min.js` convierte fotos **HEIC/HEIF** —el formato que graban los
iPhone— a JPEG dentro del navegador. Ningún navegador salvo Safari sabe abrir
HEIC de forma nativa, ni tampoco el paquete `image` de Dart, así que sin esto
un usuario web con fotos de iPhone no puede ponerse foto de perfil.

## Por qué está aquí y no en un CDN

Servirlo desde el propio sitio evita depender de un tercero (si su CDN cae, la
feature cae) y evita que la IP de cada usuario acabe en los registros de otra
empresa.

## Por qué no se carga siempre

Pesa ~1,4 MB. `lib/core/utils/heic_decoder_web.dart` inyecta el `<script>`
**la primera vez que alguien elige una foto HEIC**, y solo entonces. Quien
suba un JPEG o un PNG no descarga ni un byte de esto.

Si el fichero no está, `_ensureDecoderLoaded()` recibe un error de carga y
devuelve `false`: la app sigue funcionando y muestra el mensaje de siempre.
No rompe nada, simplemente no convierte.

## Cómo actualizarlo

Descargar la versión nueva desde
`https://cdn.jsdelivr.net/npm/heic2any@<version>/dist/heic2any.min.js` y
sustituir el fichero. La detección de HEIC (por cabecera, no por extensión)
está en `describeImageBytes()` / `isHeicContainer()`, en
`lib/core/utils/image_processing.dart`.
