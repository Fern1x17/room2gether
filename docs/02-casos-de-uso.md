# Casos de Uso — Room2gether

> Plantilla. Añade y detalla los casos de uso. Formato sugerido abajo.

## Actores

- **Usuario:** persona que busca u ofrece compañero/habitación.
- **Inmobiliaria:** cliente B2B que publica anuncios (Fase 3).
- **Sistema:** la app/backend.

## Plantilla de caso de uso

### CU-XX: [Nombre]

- **Actor principal:**
- **Precondición:**
- **Flujo principal:**
  1. ...
  2. ...
- **Flujos alternativos:**
  - ...
- **Postcondición:**

---

## Casos de uso principales (esbozo, a detallar)

### CU-01: Registrarse

- **Actor:** Usuario
- **Precondición:** No tiene cuenta.
- **Flujo principal:**
  1. Abre la app y elige "Registrarse".
  2. Introduce email/contraseña o usa Google.
  3. Confirma ser mayor de edad.
  4. Acepta la política de privacidad.
  5. El sistema crea la cuenta y lleva al onboarding de perfil.
- **Postcondición:** Cuenta creada, perfil pendiente de completar.

### CU-02: Iniciar sesión

- **Actor:** Usuario
- **Precondición:** Tiene una cuenta y la sesión cerrada.
- **Flujo principal:**
  1. Abre la app y elige iniciar sesión.
  2. Introduce email y contraseña.
  3. El sistema valida las credenciales y abre la sesión.
- **Flujos alternativos:**
  - Credenciales incorrectas: el sistema muestra un error y permite reintentar.
- **Postcondición:** La sesión queda iniciada.

### CU-03: Eliminar cuenta

- **Actor:** Usuario
- **Precondición:** Tener una cuenta y la sesión abierta.
- **Flujo principal:**
  1. Abre la app y entra en el perfil.
  2. Selecciona eliminar cuenta.
  3. Selecciona confirmar.
- **Postcondición:** El perfil se elimina de la base de datos¡.

### CU-04: Modificar perfil

- **Actor:** Usuario
- **Precondición:** Tener una cuenta y la sesión abierta.
- **Flujo principal:**
  1. Abre la app y entra en el perfil.
  2. Selecciona la opción de modificar perfil.
  3. Se introducen los nuevos datos.
  4. Se confirman los datos.
- **Postcondición:** El perfil queda actualizado con los nuevos datos.

### CU-05: Cerrar sesión

- **Actor:** Usuario
- **Precondición:** Tener la sesión abierta.
- **Flujo principal:**
  1. Abre la app y entra en el perfil.
  2. Selecciona la opción de cerrar sesión.
  3. Se confirma cerrar sesión.
- **Postcondición:** La sesión queda cerrada.

### CU-06: Crear publicación

- **Actor:** Usuario
- **Precondición:** No tiene ninguna publicación activa. Tener la sesión iniciada.
- **Flujo principal:**
  1. Abre la app y elige crear publicación.
  2. Selecciona si ya tiene piso y busca compañero o si busca piso y compañero.
     2.1. Si ya tiene piso se deben adjuntar imágenes y seleccionar el precio por mes.
     2.2. Si no tiene piso selecciona un rango de mínimo y máximo presupuesto que esté dispuesto a pagar.
  3. Se introduce la ciudad y la dirección/barrio en el que está ubicado el piso o se desea buscar
     (si se está buscando piso, el barrio se puede dejar como "cualquiera").
  4. Se puede escribir una pequeña descripción y posteriormente se publica.
- **Comentarios:** Cuando se escribe la dirección del piso, el usuario podrá elegir si mostrar la dirección completa o solo el barrio. Tambien si el usuario no escribe la dirección completa y por ejemplo solo pone el barrio no debe dar error y será eso lo que se muestre
- **Postcondición:** Publicación creada, cualquiera puede verla y contactar.

### CU-07: Eliminar publicación

- **Actor:** Usuario
- **Precondición:** Tiene una publicación activa. Tener la sesión iniciada.
- **Flujo principal:**
  1. Abre la app, entra en el perfil y selecciona una publicación.
  2. Se selecciona eliminar publicación.
  3. Se confirma.
- **Postcondición:** La publicación queda eliminada de la base de datos y del perfil.

### CU-08: Modificar publicación

- **Actor:** Usuario
- **Precondición:** Tiene una publicación activa. Tener la sesión iniciada.
- **Flujo principal:**
  1. Abre la app, entra en el perfil y selecciona una publicación.
  2. Se selecciona modificar publicación.
  3. Se modifican los parámetros deseados.
  4. Se confirma.
- **Postcondición:** La publicación queda guardada con los nuevos datos.

### CU-09: Explorar y filtrar el feed

- **Actor:** Usuario
- **Precondición:** Tener la sesión abierta
- **Flujo principal:**
  1. Abre la app y elige buscar.
  2. Se seleccionan los filtros de búsqueda (ciudad, barrio, precio, estado...).
  3. Aparece una ventana con todas las publicaciones que cumplan los requisitos.
- **Comentarios:** Si el usuario tiene la sesión abierta, aparte del botón de buscar, en la pantalla
  principal aparecerán publicaciones de la ciudad que haya seleccionado y un botón para seleccionar filtros.
- **Postcondición:** Queda guardado un registro de las búsquedas recientes.

### CU-10: Contactar por chat

- **Actor:** Usuario
- **Precondición:** Tener la sesión abierta. Que exista una publicación.
- **Flujo principal:**
  1. Abre la app y selecciona una publicación de la feed.
  2. Selecciona la opción de enviar mensaje.
  3. Escribir el mensaje.
- **Postcondición:** Se crea un chat entre los 2 usuarios y se guarda cifrado.

### CU-11: Reportar / bloquear

- **Actor:** Usuario
- **Precondición:** Tener la sesión abierta. Que el usuario reportado sea una cuenta existente y tenga una publicación creada o un chat abierto.
- **Flujo principal:**
  1. Abre la app y entra en una publicación o en un chat existente.
  2. Se selecciona un botón de opciones y se elige la razón de reportar.
  3. Se seleccionan los motivos del reporte y se bloquea al usuario.
- **Postcondición:** El usuario reportado debe aparecer como bloqueado para el usuario que hace el reporte.

### CU-12: Destacar publicación (pago)

- **Actor:** Usuario
- **Precondición:** Tener la sesión abierta y una publicación creada.
- **Flujo principal:**
  1. Abre la app, entra en el perfil y selecciona una publicación no destacada.
  2. Selecciona la opción de destacar.
  3. Se procesa el pago.
- **Postcondición:** La publicación debe aparecer como destacada durante 7 días. Es decir, aparecer entre las primeras publicaciones al buscar en esa ciudad.

===== REQUISITOS DE MODERACIÓN =====

## CU-13: Registrar moderador

- **Actor:** Moderador
- **Precondición:** Tener un correo válido para moderador (correo de la empresa)
- **Flujo principal:**
  1. Abre la app y entra en crear cuenta
  2. Introduce su correo de la empresa (@room2gether.com por ejemplo) y la contraseña
  3. Introduce edad
  4. Confirmar email
- **Postcondición:** La cuenta debe quedar registrada en la base de datos

## CU-14: Eliminar usuario

- **Actor:** Moderador
- **Precondición:** Tener abierta sesión en una cuenta de moderador
- **Flujo principal:**
  1. Abre la app y selecciona un usuario. (desde una publicación o buscándolo)
  2. Selecciona la opción de eliminar cuenta
  3. Confirmar
- **Postcondición:** La cuenta debe haber sido eliminada de la base de datos

## CU-15: Eliminar publicación mod

- **Actor:** Moderador
- **Pecondición:** Tener abierta sesión en una cuenta de moderador
- **Flujo principal:**
  1. Abre la app y selecciona una publicación
  2. Selecciona la opción de eliminar
  3. Confirmar
- **Postcondición:** La publicación debe haber sido borrada de la base de datos

### CU-16: Modificar publicación mod

- **Actor:** Moderador
- **Precondición:** Tener la sesión abierta en una cuenta de moderador
- **Flujo principal:**
  1. Abre la app y selecciona una publicación.
  2. Se selecciona modificar publicación.
  3. Se modifican los parámetros deseados.
  4. Se confirma.
- **Postcondición:** La publicación queda guardada con los nuevos datos.

### CU-17: Crear publicación

- **Actor:** Moderador
- **Precondición:** Tener la sesión abierta en una cuenta de moderador
- **Flujo principal:**
  1. Abre la app y elige crear publicación.
  2. Selecciona si ya tiene piso y busca compañero o si busca piso y compañero.
     2.1. Si ya tiene piso se deben adjuntar imágenes y seleccionar el precio por mes.
     2.2. Si no tiene piso selecciona un rango de mínimo y máximo presupuesto que esté dispuesto a pagar.
  3. Se introduce la ciudad y el barrio en el que está ubicado el piso o se desea buscar
     (si se está buscando piso, el barrio se puede dejar como "cualquiera").
  4. Elegir un usuario estándar al cual estará vinculada la publicación. Si es nulo será el propio moderador
  5. Se puede escribir una pequeña descripción y posteriormente se publica.
- **Postcondición:** Publicación creada, cualquiera puede verla y contactar.

### CU-18: Guardar en favoritos

- **Actor:** Ususario
- **Precondición:** Tener la sesión abierta
- **Flujo principal:**
  1. Abrir la app y entrar en una publicación
  2. Seleccionar añadir a favoritos
  3. Confirmar
- **Postcondición:** La publicación deberá quedar guardada en la pestaña de favoritos del usuario

### CU-19: Ver perfil

- **Actor:** Ususario
- **Precondición:** Tener la sesión abierta
- **Flujo principal:**
  1. Abrir la app y seleccionar una publicación o buscar un perfil en el buscador
  2. Presionar sobre un perfil de usuario
  3. Aparecerán todos los datos publicos del perfil seleccionado
- **Postcondición:** Los datos del perfil seleccionado deben aparecer por pantalla

### CU-20: Buscar usuario

- **Actor:** Usuario
- **Precondición:** Tener la sesión abierta
- **Flujo principal:**
  1. El usuario entra en el buscador con el icono de una lupa arriba a la derecha
  2. Escribe el nombre de usuario del perfil que desea buscar
  3. A medida que se va escribiendo el nombre, iran apareciendo una lista de usuarios que tengan ese nombre o parecido y al lado su foto de perfil
- **Postcondición:** N/A

### CU-xx: (Fase 3) Inmobiliaria publica anuncio

/_ No implementar por ahora _/

- **Actor:** Inmobiliaria
- **Precondición:** Cuenta de inmobiliaria dada de alta (cliente B2B) y sesión iniciada.
- **Flujo principal:**
  1. Accede al panel de inmobiliaria y elige publicar un anuncio.
  2. Introduce los datos del piso/habitación (ciudad, barrio, precio, fotos, descripción).
  3. El sistema marca la publicación como perteneciente a una inmobiliaria.
  4. Publica el anuncio.
- **Flujos alternativos:**
  - Suscripción o pago pendiente: el sistema bloquea la publicación hasta regularizar el pago.
- **Postcondición:** El anuncio queda visible en el feed junto a las publicaciones de particulares, identificado como profesional.
