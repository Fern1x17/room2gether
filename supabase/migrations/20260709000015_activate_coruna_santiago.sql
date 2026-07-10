-- Activa A Coruña y Santiago de Compostela en el catálogo de ciudades:
-- pasan a aparecer en el selector con autocompletado (RF-15). Ya existían
-- en el seed como inactivas, con sus normalized_name y aliases.

update public.cities
set is_active = true
where normalized_name in ('a coruna', 'santiago de compostela');
