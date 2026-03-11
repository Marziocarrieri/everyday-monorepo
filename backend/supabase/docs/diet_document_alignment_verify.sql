-- diet_document alignment verification SQL
-- Run this before and after applying the migration.

-- STEP 1: Current schema inspection

-- Columns
SELECT
  ordinal_position,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'diet_document'
ORDER BY ordinal_position;

-- Constraints
SELECT
  c.conname AS constraint_name,
  c.contype AS constraint_type,
  pg_get_constraintdef(c.oid) AS definition
FROM pg_constraint c
JOIN pg_class t ON t.oid = c.conrelid
JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname = 'public'
  AND t.relname = 'diet_document'
ORDER BY c.conname;

-- Indexes
SELECT
  i.relname AS index_name,
  ix.indisunique AS is_unique,
  pg_get_indexdef(ix.indexrelid) AS index_definition
FROM pg_class t
JOIN pg_namespace n ON n.oid = t.relnamespace
JOIN pg_index ix ON ix.indrelid = t.oid
JOIN pg_class i ON i.oid = ix.indexrelid
WHERE n.nspname = 'public'
  AND t.relname = 'diet_document'
ORDER BY i.relname;

-- RLS state
SELECT
  c.relrowsecurity AS rls_enabled,
  c.relforcerowsecurity AS rls_forced
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname = 'diet_document';

-- Policies
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'diet_document'
ORDER BY policyname;

-- STEP 7: Final verification checks

-- Null household rows must be 0
SELECT count(*) AS null_household_id_rows
FROM public.diet_document
WHERE household_id IS NULL;

-- Final schema snapshot (quick view)
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'diet_document'
ORDER BY ordinal_position;

-- Sample RLS-scoped SELECT test query (run as authenticated user)
SELECT
  d.id,
  d.household_id,
  d.user_id,
  d.url,
  d.uploaded_at
FROM public.diet_document d
WHERE d.user_id = auth.uid()
  AND d.household_id IN (
    SELECT hm.household_id
    FROM public.household_member hm
    WHERE hm.user_id = auth.uid()
  )
ORDER BY d.uploaded_at DESC
LIMIT 5;
