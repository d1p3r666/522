-- Run with psql -v ON_ERROR_STOP=1 or in the pgAdmin Query Tool.
SELECT version();

BEGIN;
CREATE TABLE IF NOT EXISTS public.compose_lab_notes (
    id integer PRIMARY KEY,
    topic text NOT NULL
);
INSERT INTO public.compose_lab_notes (id, topic) VALUES
    (1, 'Docker Compose'),
    (2, 'PostgreSQL'),
    (3, 'pgAdmin')
ON CONFLICT (id) DO NOTHING;
COMMIT;

SELECT id, topic FROM public.compose_lab_notes ORDER BY id;
SELECT count(*) AS row_count FROM public.compose_lab_notes;
