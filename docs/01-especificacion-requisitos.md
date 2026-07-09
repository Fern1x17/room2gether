# Especificación de Requisitos — Roomie

## 1. Visión del producto
App para encontrar compañeros de piso. Contacto gratis entre usuarios.
Monetización vía anuncios B2B de inmobiliarias y destacados de pago.

## 2. Usuarios objetivo
- Estudiantes y jóvenes profesionales que buscan habitación/compañero.
- Inmobiliarias y residencias (clientes B2B, Fase 3).
- Particulares con pisos que quieran alquilarlos

## 3. Usuarios de mantenimiento
- Moderadores dentro de la empresa

## 4. Requisitos funcionales (MVP)

| ID | Requisito | Prioridad |
|----|-----------|-----------|
| RF-01 | Registro, login y cierre de sesión (email + Google) | Alta |
| RF-02 | Verificación de edad (mayor de edad) | Alta |
| RF-03 | Aceptación de política de privacidad (RGPD) | Alta |
| RF-04 | Crear y editar perfil con preferencias de convivencia o datos personales (foto de perfil, nombre de usuario)| Alta |
| RF-05 | Crear, editar y eliminar publicación (busco / ofrezco) con fotos | Alta |
| RF-06 | Feed de publicaciones con filtros (zona, precio, tipo) | Alta |
| RF-07 | Chat in-app en tiempo real | Alta |
| RF-08 | Reportar usuario o publicación | Alta |
| RF-09 | Bloquear usuario | Media |
| RF-10 | Destacar publicación (pago ~5€) | Media (Fase 2) |
| RF-11 | Panel para inmobiliarias | Baja (Fase 3) |
| RF-12 | Eliminar cuenta (derecho al olvido, RGPD) | Alta |
| RF-13 | Al cerrar la app la sesión debe quedar abierta al volver a entrar si el usuario no la cerró
| RF-14 | Moderación (eliminar cuentas/publicaciones, modificarlas, etc.)
| RF-15 | Buscador de ciudades inteligente. Al escribir el nombre de la ciudad aparecerán ciudades con nombre parecido para seleccionar una de ellas
| RF-16 | Poder cambiar la contraseña del usuario
| RF-17 | Notificaciones de mensajes

## 5. Requisitos no funcionales
- RGPD y protección de datos personales.
- Rendimiento fluido en gama media de Android.
- Escalable (preparado para crecer de 1 ciudad a varias).
- Disponibilidad y seguridad (RLS en toda la BD).
- Cifrado de mensajes en los chats
- Diseño profesional y cuidado.
- Versión web

## 6. Fuera de alcance (por ahora)
- Pagos de reservas/depósitos entre usuarios.
- Multi-idioma.
