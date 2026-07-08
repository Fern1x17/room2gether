-- CU-10: chat en tiempo real (RF-07). Añade messages a la publicación de
-- Realtime para que los clientes puedan suscribirse a los INSERT en vivo.
-- RLS sigue aplicando: cada cliente solo recibe mensajes de conversaciones
-- en las que participa.

alter publication supabase_realtime add table public.messages;
