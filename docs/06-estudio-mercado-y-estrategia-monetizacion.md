# Estudio de mercado y estrategia de monetización — Roomie

> Documento de estrategia de negocio. Pensado para vivir en `docs/` del repo y servir de contexto
> a Claude Code. Fecha de elaboración: julio 2026. Fuentes: idealista/data (T1 2026), JLL,
> Ministerio de Universidades, Badi (canales oficiales y Trustpilot), portales locales de Vigo.
>
> **Premisa central que gobierna todo el documento:** el usuario español de este mercado es
> extremadamente sensible al precio. El estudiante no pagará casi nunca por buscar piso, y
> propietarios e inmobiliarias comparan precios y eligen lo más barato. La estrategia no lucha
> contra esta realidad: la convierte en el arma competitiva principal.

---

## 1. El mercado

### 1.1 Dimensión nacional y tendencias

El mercado objetivo es grande, crece y está estructuralmente desabastecido. España registró
1.762.459 estudiantes universitarios matriculados en el curso 2023-24, el máximo de su historia,
con un crecimiento sostenido de ~2% anual desde 2019. De ellos, unos 417.000 se desplazaron a otra
provincia para estudiar en el curso 2024-25 (+2,9% interanual), a los que se suman ~170.000
estudiantes internacionales (64.000 vía Erasmus+). Ese bloque de ~590.000 personas que cada año
necesita techo fuera de casa es el mercado direccionable directo de Roomie, y se renueva
parcialmente cada septiembre.

La oferta formal no da abasto: las residencias de estudiantes suman ~106.000-111.000 camas frente
a una demanda estimada de más de 594.000-655.000, un déficit de ~482.000 camas según JLL (335.000
proyectadas aún sin cubrir en 2029-30). **Consecuencia estructural: la inmensa mayoría de la
demanda estudiantil se resuelve en el piso compartido**, que es exactamente el terreno de Roomie.

El propio mercado de habitaciones está en expansión: la oferta de habitaciones en piso compartido
creció un 22% interanual en el T1 de 2026, con un precio medio nacional de 430 €/mes. Cada vez más
propietarios optan por alquilar por habitaciones como estrategia de rentabilización — es decir, el
segmento "casero particular que alquila a estudiantes" (cliente de la Pata 2 de monetización) está
creciendo, no menguando. En Galicia el fenómeno es especialmente visible: Ourense fue una de las
capitales con mayor crecimiento de oferta de habitaciones (+76% interanual).

Dato estratégico clave: la mitad de la oferta nacional de habitaciones se concentra en Madrid
(22%), Valencia (13%), Barcelona (12%) y Sevilla. **Las ciudades universitarias medianas están
desatendidas por los grandes operadores** — es donde una app local puede alcanzar densidad
dominante con presupuesto de guerrilla.

### 1.2 El mercado local de lanzamiento: Vigo

- **Demanda:** la Universidade de Vigo ronda los 20.000-30.000 estudiantes repartidos en tres
  campus (Vigo, Pontevedra, Ourense), siendo Vigo el mayor, con ~2.000 alumnos nuevos de grado
  cada año solo en su campus. El campus principal (As Lagoas, Marcosende) está a ~11 km del
  centro, de modo que el alumnado vive en la ciudad y se desplaza en lanzadera — es decir,
  la demanda de habitación se concentra en el casco urbano, no alrededor del campus.
- **Precios:** habitación media en Vigo ~250-300 €/mes (rango observado 170-400 €; los anuncios
  activos en 2026 se mueven mayoritariamente entre 230 y 370 € con gastos incluidos). El curso
  típico va de septiembre a junio, con contratos de 9-10 meses.
- **Competencia local:** fragmentada y débil. Idealista/Fotocasa como generalistas; webs locales
  pequeñas y anticuadas (Cuvi, Rentalgalicia); gestoras de habitaciones tipo Novavivenda Rooms
  (que, ojo, son clientes B2B potenciales, no solo competencia); Spotahome con presencia
  testimonial; y sobre todo los canales informales: grupos de Facebook y WhatsApp, tablones de
  facultad y boca a boca.
- **Implicación:** un mercado de este tamaño limita el techo de ingresos por ciudad (ver §4),
  pero el coste de dominarlo es bajísimo y sirve de laboratorio del playbook replicable.
- **Expansión natural:** Santiago de Compostela (USC, ciudad con la mayor densidad estudiantil
  de Galicia) y A Coruña (UDC) como ciudades 2 y 3. Mismo idioma, misma cultura de mercado,
  distancias cortas para el trabajo de campo.

### 1.3 Competencia y sus modelos de cobro

| Competidor | Modelo de cobro | Precios observados | Debilidad explotable |
|---|---|---|---|
| **Badi** (líder en habitaciones) | Freemium agresivo: publicar es gratis pero responder/contactar sin límite exige pagar | Badi Gold: 19,99 €/anuncio/30 días; extras entre 5,99 y 21,99 €; comisión de reserva ~11% de la primera mensualidad | Trustpilot 1,8/5. Quejas masivas: pagar sin resultados, sensación de perfiles falsos como cebo, tener que repagar cada mes. Ha quemado la confianza del usuario |
| **Idealista** (gigante generalista) | Particulares: 2 anuncios gratis (+5 habitaciones gratis); pago a partir de ahí. Destacados desde ~44-47 €. Agencias: 60-300+ €/mes | Ver columna anterior | Centrado en el inmueble, no en la persona: cero matching de convivencia, cero enfoque estudiante, contactos sin filtrar para el anunciante |
| **Fotocasa, Pisocompartido, Roomgo, Roomster** | Variantes freemium con contacto limitado o de pago | Diverso | Mismos vicios que Badi con menos volumen |
| **Spotahome / Uniplaces / Erasmus Play** | Comisión sobre reserva online | % de la primera mensualidad | Caros, foco internacional, inventario mínimo en ciudades medianas |
| **Canales informales** (Facebook, WhatsApp, tablones) | Gratis | 0 € | Estafas frecuentes, sin filtros ni perfiles, caos. Es el competidor real del usuario tacaño y a la vez la prueba de que la demanda tolera fricción con tal de no pagar |

### 1.4 Síntesis: la tacañería no es el problema, es el hueco

Todo el sector ha intentado monetizar al que busca, y el resultado es un líder con 1,8 sobre 5 en
Trustpilot y usuarios refugiados en grupos de Facebook. La conclusión no es "no hay dinero aquí";
es que **el dinero está en el lado equivocado del mostrador**. Quien busca habitación no paga.
Quien gana dinero gracias al que busca — el casero con la habitación vacía, la gestora, la
residencia con camas por llenar, la marca que quiere venderle al público 18-25, la teleco que
quiere el alta de internet del piso nuevo — ese sí paga, y paga sin drama si el precio se enmarca
contra lo que ya pierde o ya gasta.

---

## 2. Disposición a pagar por segmento (análisis honesto)

| Segmento | Dolor real | Alternativa gratis que tiene | DAP realista | Cómo se le cobra |
|---|---|---|---|---|
| Estudiante que **busca** | Alto, pero sin dinero | Facebook, WhatsApp, Idealista | **≈ 0 €. Aceptarlo.** | No se le cobra. Nunca. Es la audiencia |
| Estudiante/joven que **ofrece** hueco en su piso | Medio: la habitación vacía encarece su parte del alquiler | Publicar gratis en todas partes | Baja pero > 0: micropago puntual | Destacado 3-5 € opcional |
| **Casero particular** (alquila piso/habitaciones a estudiantes, no vive allí) | Alto: habitación vacía = 250-430 €/mes perdidos; piso vacío en Vigo = 600-900 €/mes | Idealista (2 anuncios gratis), Wallapop, Facebook | Media **si hay prueba de resultados** | Freemium: 1er anuncio gratis con métricas; renovar/ampliar de pago |
| **Inmobiliaria local / gestora de habitaciones** | Medio-alto: captar inquilino joven les cuesta tiempo y publicidad | Su escaparate, Idealista (pero les cuesta 60-300 €/mes) | Media-alta, pero comparan todo | Suscripción barata self-service, sin permanencia, anclada contra Idealista |
| **Residencias de estudiantes** | Alto: déficit estructural pero competencia por captar en apertura y en ciudades medias; CAC alto en Google/Instagram | Su propio marketing | Alta | Publicidad nativa / coste por lead |
| **Marcas** (banco cuenta joven, teleco, gimnasio, academia, mudanzas) | Quieren al público 18-25 hiperlocalizado | Instagram Ads (caro y disperso) | Alta: ya tienen presupuesto de marketing | Patrocinio local mensual |
| **Proveedores de servicios** (luz, internet, seguros hogar/impago) | Cada mudanza es un alta potencial | — | Pagan **por resultado** | Afiliación: no lo paga nadie de la plataforma |

Lectura del cuadro: los dos primeros segmentos financian la app con su *presencia*, no con su
dinero. Los cinco restantes son las fuentes de ingreso, ordenadas de menor a mayor ticket.

---

## 3. Estrategia de monetización

### 3.0 Los cinco principios (reglas de oro)

1. **Gratis radical para el que busca, para siempre, y como promesa pública de marca.** Buscar,
   contactar y chatear no costarán nunca nada. Es el anti-Badi, el motor de adquisición y el foso
   competitivo: Badi no puede copiarlo sin dinamitar su propia línea de ingresos.
2. **Nunca se vende "una app"; se venden resultados enmarcados contra un coste que el cliente ya
   sufre.** Al casero no se le dice "publica por 25 €": se le dice "una habitación vacía te cuesta
   300 € cada mes; esto te la llena antes". A la inmobiliaria no se le compara con "gratis": se le
   compara con los 60-300 €/mes de Idealista y con el coste de su publicidad actual.
3. **Nadie paga a ciegas.** Todo cobro llega después de una prueba de valor con métricas visibles
   ("tu anuncio: 214 vistas, 11 contactos este mes"). Primero demostrar, luego cobrar.
4. **Todo lo que cueste menos de 100 € se compra solo (self-service).** Sin llamadas, sin
   reuniones. El tiempo del fundador es el recurso más escaso de la empresa; las ventas
   comerciales se reservan para residencias y patrocinios.
5. **Cuatro patas de ingreso, ninguna imprescindible.** La diversificación es la garantía de que
   la empresa "no se va a la mierda" si una pata falla o tarda.

### 3.1 Pata 1 — Micropagos de visibilidad (activar en Fase 2, ~mes 6)

Destacados de 3-5 € para quien **ofrece** habitación o piso (nunca para quien busca). Compra
impulsiva, autoservicio, sin fricción. Conversión esperada realista: 1-3% de los anuncios activos.
Techo bajo (~100-300 €/mes por ciudad tamaño Vigo), pero cumple dos funciones que valen más que su
importe: valida que el mercado local paga algo, y entrena el músculo de pagos (Stripe, facturas,
IVA) con importes en los que un error no duele.

### 3.2 Pata 2 — Caseros particulares y minipropietarios (activar Fase 2-3, ~mes 8)

El modelo validado en la conversación previa: **pago por publicar, no comisión** (evita la fuga de
la transacción y el choque con el contacto gratis).

- Primer anuncio **gratis** con panel de métricas visible (vistas, contactos). La cohorte
  fundadora (todos los que publiquen antes del arranque del cobro) mantiene gratis su anuncio
  activo — convierte a los primeros usuarios en prescriptores en vez de en enfadados.
- A partir de ahí: **19-29 € por publicación** (activa todo el curso o hasta alquilarse) o **plan
  49 €/año** para quien gestiona 2-4 inmuebles.
- Argumento de venta: audiencia 100% estudiantes de su ciudad + **grupos preformados** (ver §3.6)
  + precio inferior al destacado de Idealista (~44 €) y una fracción de un solo mes de vacancia.
- Antifraude y antidisfraz: DNI obligatorio para cuentas de particular, límite de anuncios por
  cuenta (las agencias camufladas de particular son el problema eterno de Idealista), botón de
  denuncia visible.
- Techo por ciudad tamaño Vigo: ~100-200 publicaciones de pago/año ≈ 250-450 €/mes.

### 3.3 Pata 3 — B2B recurrente: inmobiliarias, gestoras y residencias (Fase 3, ~mes 10-12)

La pata de mayor calidad de ingreso (recurrente y predecible), rediseñada para clientes que
comparan precios:

| Plan | Precio | Incluye | Diseñado para |
|---|---|---|---|
| **Escaparate** | 29-49 €/mes, autoservicio, sin permanencia | Perfil de empresa + hasta 5 anuncios + estadísticas | Que la decisión no necesite aprobación de nadie: es "probar", no "contratar" |
| **Pro** | 99-149 €/mes | Anuncios ilimitados + destacados incluidos + branding + prioridad en resultados | Gestoras de habitaciones y agencias con volumen |
| **Residencias / lead-gen** | Presencia patrocinada o coste por lead (venta directa) | Ficha destacada permanente + leads cualificados | Residencias y colivings; se negocia, no se tarifica en web |

Tácticas anti-tacañería: sin permanencia (elimina el miedo), descuento ~20% por pago anual
(adelanta caja y alisa la estacionalidad), anclaje explícito contra Idealista (60-300 €/mes) y
contra su gasto actual en Instagram/Google. Objetivo realista en ciudad 1: 8-15 clientes de pago →
400-1.200 €/mes.

### 3.4 Pata 4 — Ingresos que no paga nadie de la plataforma (activable desde Fase 2; la más subestimada)

**a) Afiliación de servicios de mudanza.** Cada contrato cerrado dispara altas de luz, internet,
seguro de hogar y, en el lado del casero, seguros de impago. Los comparadores y gestores de altas
pagan comisión por conversión (habitualmente decenas de euros por alta; **cifra exacta a validar**
firmando con 2-3 redes de afiliación o partners directos — investigar Selectra, papernest, redes
tipo Awin/TradeTracker). Es la forma de monetizar la transacción **sin cobrar comisión a nadie**:
paga la teleco. Encaja de forma nativa: un checklist de mudanza post-match ("¿ya tenéis wifi en el
piso nuevo?") ayuda de verdad al usuario y convierte.

**b) Patrocinios de marca.** 1-3 marcas por ciudad (banco con cuenta joven, teleco, gimnasio,
academia, empresa de mudanzas) con presencia nativa y no invasiva: 100-300 €/mes por marca a nivel
local. Requiere audiencia demostrable (≥3.000 usuarios activos/mes en la ciudad). A escala
regional/nacional los tickets suben un orden de magnitud.

**c) Lo que NO haremos con publicidad:** nada de AdMob/banners programáticos al lanzamiento.
Ingresan céntimos, degradan la percepción de calidad y espantan justo a los B2B que sí pagan
cientos. Solo se reconsiderará como suelo de ingresos con mucho volumen.

### 3.5 Lo que descartamos y por qué (tan importante como lo anterior)

No cobraremos por contactar (es el foso de Badi y nuestra razón de existir). No habrá comisión
obligatoria sobre la transacción (fuga garantizada + choque frontal con el contacto gratis; una
"reserva segura" opcional queda aparcada para una fase muy posterior, si acaso). No habrá
suscripción premium para el estudiante que busca. No se venderán datos de usuarios (el RGPD lo
restringe y la confianza es el único activo real de una plataforma de vivienda).

### 3.6 El multiplicador de todas las patas: los grupos

La funcionalidad de **formar grupo dentro de la app** (2-4 estudiantes compatibles que se
constituyen como grupo y contactan juntos) convierte el core de matching en el embudo comercial de
todo lo demás: para el casero de piso entero, un grupo preformado vale más que diez contactos
sueltos (y justifica su pago); para la inmobiliaria, es un lead cualificado imposible de conseguir
en Idealista; para la afiliación, un grupo que firma es un piso entero dándose de alta en
suministros. Es la pieza de producto que ningún generalista puede copiar rápido y la que hay que
comunicar en toda la venta B2B.

---

## 4. Viabilidad económica: que la empresa no se vaya a la mierda

### 4.1 Recordatorio de la estructura de costes (del análisis fiscal previo)

Año 1 con tarifa plana de autónomo: ~164 €/mes de gastos fijos. Régimen estable: punto de
equilibrio en ~330-350 €/mes de facturación. Sueldo modesto de ~1.500 € netos/mes: requiere
facturar ~2.700-2.900 €/mes (sin IVA).

### 4.2 Escenarios de ingresos (una ciudad tamaño Vigo)

| Fuente | Prudente (mes 12-18) | Objetivo (mes 18-24) |
|---|---|---|
| Destacados (Pata 1) | 100 € | 200 € |
| Caseros particulares (Pata 2) | 250 € | 400 € |
| B2B recurrente (Pata 3) | 8 clientes × ~39 € = 310 € | 12 clientes × ~59 € = 710 € |
| Afiliación (Pata 4a) | 150 € | 400 € |
| Patrocinios (Pata 4b) | 150 € | 300 € |
| **Total/mes** | **~960 €** | **~2.010 €** |

Lecturas honestas de la tabla:

1. El escenario prudente **cubre holgadamente los costes** (~3× el break-even) pero no paga un
   sueldo. El objetivo se acerca al sueldo pero no llega. **Una sola ciudad del tamaño de Vigo
   plafona, siendo realistas, en 1.500-2.500 €/mes.**
2. La conclusión no es que el negocio no funcione: es que el negocio es un **playbook
   replicable**. El sueldo digno llega con la ciudad 2 y 3 (Santiago, A Coruña), donde el coste
   marginal de replicar es una fracción del de la primera. Tres ciudades en el escenario objetivo
   ≈ 4.500-6.000 €/mes de facturación.
3. Ninguna pata supera el ~35% del total: si una falla o se retrasa, la empresa no cae.

### 4.3 Estacionalidad y caja

El 60-70% de la actividad del sector ocurre entre junio y octubre. Implicaciones operativas: los
planes anuales B2B con descuento existen sobre todo para **cobrar por adelantado y alisar la
caja**; la temporada baja (noviembre-mayo) se dedica a venta B2B, producto y preparación de la
siguiente ciudad; y jamás debe proyectarse el ingreso de septiembre como si fuera mensual
recurrente.

### 4.4 Puertas de activación (no se activa un cobro sin su métrica)

| Cobro | Se activa solo cuando… |
|---|---|
| Destacados (Pata 1) | ≥ 500 usuarios activos/mes en la ciudad y ≥ 100 anuncios vivos |
| Pago caseros (Pata 2) | El anuncio mediano recibe ≥ 8 contactos/mes (hay valor que enseñar) |
| B2B (Pata 3) | ≥ 2.000 usuarios activos/mes en la ciudad + casos de éxito de la Pata 2 |
| Patrocinios (Pata 4b) | ≥ 3.000 usuarios activos/mes en la ciudad |
| Afiliación (Pata 4a) | Desde que exista el flujo post-match (no requiere masa crítica) |

Activar un cobro antes de su puerta destruye confianza para siempre a cambio de calderilla. Es la
disciplina que separa este plan del modelo Badi.

---

## 5. Riesgos principales y mitigación

**Arranque en frío (riesgo nº 1, muy por encima del resto).** Sin densidad local no hay nada que
monetizar. Mitigación: una sola ciudad, cohorte fundadora con beneficios vitalicios, embajadores
por facultad, presencia física en septiembre (jornadas de acogida, tablones, grupos existentes),
y sembrar oferta manualmente si hace falta (importar/captar los primeros 100 anuncios a mano).

**Que Badi o Idealista copien el modelo.** Su propia estructura de ingresos se lo impide: Badi no
puede regalar el contacto sin destruir su línea principal de ingresos, e Idealista no va a
construir matching de convivencia para un nicho. La defensa real es la densidad local y la función
de grupos.

**Fraude y estafas.** En vivienda, la confianza es el producto. DNI en caseros, moderación de
anuncios, botón de denuncia, y educación anti-estafa visible. Un solo caso viral de estafa en la
ciudad de lanzamiento puede matar la marca local.

**Fundador único.** Todo cobro < 100 € debe ser autoservicio; nada de productos que exijan soporte
intensivo; automatizar facturación desde el primer euro (Stripe + gestoría).

**Regulatorio.** Cobrar siempre al lado arrendador/anunciante alinea el modelo con la dirección de
la Ley de Vivienda 12/2023 (honorarios a cargo del arrendador) y evita el área gris de las
comisiones al inquilino. No tocar dinero de reservas elimina de raíz la complejidad de pagos,
KYC y disputas.

**Estacionalidad** (ver §4.3): riesgo de caja, no de modelo. Se gestiona con cobro anual
anticipado y colchón.

---

## 6. Hoja de ruta de activación comercial

| Periodo | Foco | Ingresos activos |
|---|---|---|
| Meses 0-6 | Producto + densidad en ciudad 1. Todo gratis. Cohorte fundadora | 0 € (deliberadamente) |
| Meses 6-9 | Puerta 1 y 4a: destacados + flujo de afiliación post-match | Pata 1, Pata 4a |
| Meses 9-12 | Puerta 2: cobro a caseros con métricas. Primeros casos de éxito documentados | + Pata 2 |
| Meses 12-18 | Puerta 3: venta B2B self-service + residencias y patrocinios en directo | + Pata 3, Pata 4b |
| Meses 18-24 | Playbook a ciudad 2 (Santiago) con lo aprendido; ciudad 1 en mantenimiento | Todas × 2 |

---

## 7. Resumen ejecutivo (para tenerlo en una pantalla)

El mercado es grande (~590.000 estudiantes/año buscan techo fuera de casa), crece, y su líder
(Badi) es odiado precisamente por cobrar al que busca (1,8/5 en Trustpilot). La tacañería del
usuario no es un obstáculo del plan: es el hueco de mercado. Roomie será gratis para siempre para
quien busca — esa es la adquisición — y cobrará solo a quien gana dinero con esa audiencia,
siempre después de demostrar valor con métricas, siempre por debajo del ancla de Idealista, y
siempre enmarcando el precio contra el coste de la vacancia. Cuatro patas de ingreso
independientes (micropagos, caseros, B2B recurrente, afiliación/patrocinios) cubren costes con
holgura en una ciudad y alcanzan un sueldo digno al replicar el playbook en la segunda y tercera.
La disciplina crítica: ningún cobro se activa antes de su puerta de métricas, y el que busca no
paga jamás.
