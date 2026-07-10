-- Corrige datos del catálogo ya aplicados:
--  1. Cinco barrios se sembraron con normalized_name que violaba el invariante
--     "minúsculas y sin tildes" (ñ/tildes/mayúsculas). Con la normalización
--     del cliente (que sí quita tildes), esos barrios eran inencontrables en
--     el selector.
--  2. El alias de Orzán se sembró como un único elemento "orzan, o orzan".
--  3. Alias adicional 'sdc' para Santiago de Compostela.
-- Idempotente: puede ejecutarse sobre datos ya corregidos sin efecto.

update public.neighborhoods set normalized_name = 'paxarinas'
where name = 'Paxariñas';

update public.neighborhoods set normalized_name = 'elvina'
where name = 'Elviña';

update public.neighborhoods
set normalized_name = 'orzan', aliases = '{"o orzan"}'
where name = 'Orzán';

update public.neighborhoods
set normalized_name = 'plaza de ourense',
    aliases = '{"pza de ourense","praza de ourense","plaza ourense","pza ourense"}'
where name = 'Plaza de Ourense';

update public.neighborhoods set normalized_name = 'estacion de autobuses'
where name = 'Estación de autobuses';

update public.cities set aliases = '{"santiago","sdc"}'
where normalized_name = 'santiago de compostela';
