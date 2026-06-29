# Especificación de Requisitos — Roomie

> Plantilla. Rellena cada sección. Mantén esto como la fuente de verdad de QUÉ
> hace la app (Claude Code lo consultará al construir features).

## 1. Visión del producto
App para encontrar compañeros de piso. Contacto gratis entre usuarios.
Monetización vía anuncios B2B de inmobiliarias y destacados de pago.

## 2. Usuarios objetivo
- Estudiantes y jóvenes profesionales que buscan habitación/compañero.
- Inmobiliarias y residencias (clientes B2B, Fase 3).

## 3. Requisitos funcionales (MVP)

| ID | Requisito | Prioridad |
|----|-----------|-----------|
| RF-01 | Registro y login (email + Google) | Alta |
| RF-02 | Verificación de edad (mayor de edad) | Alta |
| RF-03 | Aceptación de política de privacidad (RGPD) | Alta |
| RF-04 | Crear y editar perfil con preferencias de convivencia | Alta |
| RF-05 | Crear publicación (busco / ofrezco) con fotos | Alta |
| RF-06 | Feed de publicaciones con filtros (zona, precio, tipo) | Alta |
| RF-07 | Chat in-app en tiempo real | Alta |
| RF-08 | Reportar usuario o publicación | Alta |
| RF-09 | Bloquear usuario | Media |
| RF-10 | Destacar publicación (pago ~5€) | Media (Fase 2) |
| RF-11 | Panel para inmobiliarias | Baja (Fase 3) |

## 4. Requisitos no funcionales
- RGPD y protección de datos personales.
- Rendimiento fluido en gama media de Android.
- Escalable (preparado para crecer de 1 ciudad a varias).
- Disponibilidad y seguridad (RLS en toda la BD).
- Diseño profesional y cuidado.

## 5. Fuera de alcance (por ahora)
- Pagos de reservas/depósitos entre usuarios.
- Versión web.
- Multi-idioma.
