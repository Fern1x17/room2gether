# Roomie — Plataforma de búsqueda de compañeros de piso

> Este fichero lo lee Claude Code automáticamente al abrir el proyecto.
> Contiene las reglas permanentes, el contexto de negocio y el plan de trabajo.
> Mantenlo actualizado: cuando una decisión cambie, edítala aquí.

---

## 1. Qué es el proyecto

App móvil (Android primero, iOS después) donde la gente que busca compañero de
piso se registra, publica o explora anuncios de otros usuarios, y se contacta por
un chat in-app. El contacto entre usuarios es **gratis** (esto es la ventaja
competitiva frente a Badi, que cobra por contactar).

### Modelo de negocio
- **Ingreso principal:** inmobiliarias y residencias de estudiantes pagan por
  publicar anuncios de pisos/habitaciones en la plataforma (B2B).
- **Ingreso secundario (fase posterior):** usuarios pagan ~5€ para destacar su
  publicación.
- Horizonte de rentabilidad: 12–18 meses tras el lanzamiento.

### Estrategia de lanzamiento
- **UNA sola ciudad primero.** No lanzar a nivel nacional. Saturar un mercado
  local (ciudad universitaria), conseguir densidad real de usuarios, y solo
  entonces expandir. Sin masa crítica local, ninguna inmobiliaria paga.

---

## 2. Stack tecnológico

- **Frontend:** Flutter (Dart). Un solo código para Android e iOS.
- **Gestión de estado:** Riverpod.
- **Arquitectura:** feature-first (carpetas por funcionalidad, no por capa).
- **Backend:** Supabase (Auth, Postgres, Storage, Realtime para el chat).
- **Pagos:** Stripe (destacados puntuales). Valorar RevenueCat si hay suscripciones.
- **Notificaciones push:** Firebase Cloud Messaging.
- **Imágenes:** Supabase Storage o Cloudinary.
- **Mapas:** Google Maps SDK o Mapbox.
- **Control de versiones:** Git + GitHub (repo privado) desde el día 1.

---

## 3. Convenciones de código

- Código (nombres de variables, clases, ficheros) en **inglés**. Comentarios en
  español permitidos.
- Arquitectura **feature-first**: `lib/features/<feature>/` con subcarpetas
  `presentation/`, `domain/`, `data/`.
- Código compartido en `lib/core/` (theme, constantes, utilidades, cliente Supabase).
- Usar `const` en widgets siempre que sea posible.
- **Nunca** hardcodear claves API, secretos ni URLs sensibles. Usar variables de
  entorno vía `--dart-define` o `flutter_dotenv`. Las claves van en `.env` (que
  está en `.gitignore`).
- Un widget por fichero cuando el widget sea reutilizable o no trivial.
- Preferir `StatelessWidget` + Riverpod sobre `StatefulWidget` salvo necesidad real.

---

## 4. Comandos

- Ejecutar la app: `flutter run`
- Tests: `flutter test`
- Análisis estático: `flutter analyze`
- Formatear: `dart format .`
- Actualizar dependencias: `flutter pub get`

**Antes de dar una tarea por terminada:** ejecuta `flutter analyze` y `flutter test`,
y arregla cualquier warning o test roto.

---

## 5. Reglas de trabajo para Claude Code

- **Pregunta antes de añadir dependencias nuevas** (paquetes de pub.dev). Justifica
  por qué hace falta.
- **No toques la lógica de autenticación ni de pagos sin avisar primero.** Son
  zonas sensibles; explica el cambio antes de hacerlo.
- Trabaja **feature por feature**, no intentes construir todo de golpe.
- Cuando crees una pantalla nueva, sigue las convenciones de la skill `ui-conventions`.
- Cuando toques la base de datos, consulta la skill `supabase-schema`.
- Cuando escribas tests, sigue la skill `testing-guide`.
- Para cualquier cambio en la BD, propón una migración SQL; no edites datos a mano.
- Mantén los commits pequeños y con mensajes descriptivos en inglés.

---

## 6. Privacidad, legal y seguridad (NO opcional)

Esta app conecta a desconocidos y maneja datos personales + pagos. Desde el principio:

- **RGPD:** consentimiento explícito en el registro, política de privacidad
  accesible, base legal para tratar los datos.
- **Verificación de edad:** solo mayores de edad.
- **Moderación:** sistema de reporte de usuarios y de publicaciones desde el MVP.
- **Bloqueo de usuarios** en el chat.
- Datos personales **nunca** en parámetros de URL ni en logs.
- Row Level Security (RLS) activado en todas las tablas de Supabase.

> Diséñalo desde el inicio. Es mucho más barato que parchearlo después.

---

## 7. Plan de acción por fases

### Fase 0 — Validación (semanas 1–3) [NO es código]
- Hablar con 15–20 usuarios potenciales y 3–4 inmobiliarias/residencias.
- Validar cuánto pagarían las inmobiliarias y bajo qué condiciones.
- Definir la ciudad objetivo.

### Fase 1 — MVP (meses 1–4)
Funcionalidad mínima imprescindible. Construir en este orden:
1. **Auth:** registro/login (email + Google), verificación de edad, aceptación de
   RGPD.
2. **Perfil:** crear/editar perfil con preferencias de convivencia (horarios,
   limpieza, fumador, mascotas, presupuesto, zona).
3. **Feed:** lista de publicaciones filtrable por zona, precio y tipo.
4. **Publicación:** crear un anuncio (busco/ofrezco habitación) con fotos.
5. **Chat in-app:** mensajería en tiempo real (Supabase Realtime). ESTA ES LA
   FUNCIÓN CRÍTICA — es gratis y es donde la competencia falla.
6. **Reporte/bloqueo:** moderación básica.

### Fase 2 — Lanzamiento 1 ciudad + destacados (meses 5–8)
- Publicar en Google Play.
- Integrar Stripe para destacar publicaciones (~5€).
- Marketing local: universidades, grupos de Telegram/WhatsApp, Instagram local.

### Fase 3 — B2B publicitario (meses 9–18)
- Panel para inmobiliarias: crear y gestionar anuncios de pisos.
- Sistema de anuncios destacados/patrocinados en el feed.
- Métricas para vender a clientes B2B (usuarios activos mensuales por ciudad).

---

## 8. Estado actual del proyecto

> Actualiza esta sección a medida que avances. Le da contexto a Claude Code de
> dónde estás.

- [ ] Fase 0 — Validación
- [ ] Estructura base del proyecto Flutter creada
- [ ] Supabase configurado (proyecto + tablas + RLS)
- [x] Auth
- [x] Perfil
- [x] Feed
- [x] Publicación (crear CU-06, eliminar CU-07, modificar CU-08)
- [x] Chat (CU-10)
- [x] Reporte/bloqueo (CU-11)
- [ ] Lanzamiento Google Play

---

## 9. Documentación del proyecto

En `docs/` están los documentos de diseño: especificación de requisitos, casos de
uso, modelo de datos y prototipos. Consúltalos cuando trabajes en una feature
relacionada. Plantillas iniciales incluidas; rellénalas tú.
