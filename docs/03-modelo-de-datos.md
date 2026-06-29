# Modelo de Datos — Roomie

> Diagrama entidad-relación en Mermaid. Se renderiza en GitHub y en VS Code
> (con la extensión de Mermaid). Mantenlo sincronizado con la skill
> `supabase-schema` y con las migraciones reales.

```mermaid
erDiagram
    PROFILES ||--o{ LISTINGS : "publica"
    PROFILES ||--o{ MESSAGES : "envía"
    PROFILES ||--o{ REPORTS : "reporta"
    LISTINGS ||--o{ CONVERSATIONS : "origina"
    CONVERSATIONS ||--o{ MESSAGES : "contiene"
    PROFILES ||--o{ CONVERSATIONS : "participa"
    PROFILES ||--o{ BLOCKS : "bloquea"

    PROFILES {
        uuid id PK
        text display_name
        int age
        text bio
        text avatar_url
        text city
        int budget_min
        int budget_max
        bool is_smoker
        bool has_pets
        int cleanliness_level
        bool is_verified
        timestamptz created_at
    }

    LISTINGS {
        uuid id PK
        uuid owner_id FK
        text type
        text title
        text description
        text city
        text neighborhood
        int price
        bool is_featured
        timestamptz featured_until
        bool is_business
        text status
        timestamptz created_at
    }

    CONVERSATIONS {
        uuid id PK
        uuid user_a FK
        uuid user_b FK
        uuid listing_id FK
        timestamptz created_at
    }

    MESSAGES {
        uuid id PK
        uuid conversation_id FK
        uuid sender_id FK
        text content
        timestamptz read_at
        timestamptz created_at
    }

    REPORTS {
        uuid id PK
        uuid reporter_id FK
        uuid reported_user_id FK
        uuid reported_listing_id FK
        text reason
        text status
    }

    BLOCKS {
        uuid blocker_id FK
        uuid blocked_id FK
    }
```

## Notas
- Toda tabla con RLS activado (ver skill `supabase-schema`).
- `profiles.id` = `auth.users.id` de Supabase.
- Las fotos de las publicaciones pueden ir en un `text[]` o en una tabla
  `listing_photos` aparte si necesitas orden/metadatos.
