-- Safe production migration: align public.diet_document with household-scoped app logic.
-- Constraints honored:
-- - No table drops
-- - No row deletions
-- - No RLS disable
-- - Additive, production-safe changes only

-- STEP 2: Add household_id if missing.
ALTER TABLE public.diet_document
ADD COLUMN IF NOT EXISTS household_id uuid;

-- Guard: user_id is required by the new app logic and by the backfill strategy.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'diet_document'
      AND column_name = 'user_id'
  ) THEN
    RAISE EXCEPTION 'Missing required column public.diet_document.user_id. Aborting safe alignment.';
  END IF;
END
$$;

-- STEP 3: Backfill household_id from the latest membership for each diet row user.
WITH ranked_memberships AS (
  SELECT
    d.id AS diet_id,
    hm.household_id,
    row_number() OVER (
      PARTITION BY d.id
      ORDER BY hm.created_at DESC NULLS LAST, hm.id DESC
    ) AS rn
  FROM public.diet_document d
  JOIN public.household_member hm
    ON hm.user_id = d.user_id
  WHERE d.household_id IS NULL
)
UPDATE public.diet_document d
SET household_id = rm.household_id
FROM ranked_memberships rm
WHERE d.id = rm.diet_id
  AND rm.rn = 1
  AND d.household_id IS NULL;

-- Abort if any rows still cannot be backfilled; keeps migration safe and explicit.
DO $$
DECLARE
  v_null_count bigint;
BEGIN
  SELECT count(*)
  INTO v_null_count
  FROM public.diet_document
  WHERE household_id IS NULL;

  IF v_null_count > 0 THEN
    RAISE EXCEPTION
      'Backfill incomplete: % rows in public.diet_document still have household_id IS NULL',
      v_null_count;
  END IF;
END
$$;

-- STEP 4: Enforce constraint and FK.
ALTER TABLE public.diet_document
ALTER COLUMN household_id SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'diet_document_household_fk'
      AND conrelid = 'public.diet_document'::regclass
  ) THEN
    ALTER TABLE public.diet_document
      ADD CONSTRAINT diet_document_household_fk
      FOREIGN KEY (household_id)
      REFERENCES public.household(id)
      ON DELETE CASCADE;
  END IF;
END
$$;

-- STEP 5: Performance index.
CREATE INDEX IF NOT EXISTS diet_document_household_idx
  ON public.diet_document (household_id);

-- STEP 6: RLS alignment (do not disable RLS; enforce scope via restrictive policies).
ALTER TABLE public.diet_document ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'diet_document'
      AND policyname = 'diet_document_select_scope_guard'
  ) THEN
    CREATE POLICY diet_document_select_scope_guard
      ON public.diet_document
      AS RESTRICTIVE
      FOR SELECT
      TO authenticated
      USING (
        user_id = auth.uid()
        AND household_id IN (
          SELECT hm.household_id
          FROM public.household_member hm
          WHERE hm.user_id = auth.uid()
        )
      );
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'diet_document'
      AND policyname = 'diet_document_insert_scope_guard'
  ) THEN
    CREATE POLICY diet_document_insert_scope_guard
      ON public.diet_document
      AS RESTRICTIVE
      FOR INSERT
      TO authenticated
      WITH CHECK (
        user_id = auth.uid()
        AND household_id IN (
          SELECT hm.household_id
          FROM public.household_member hm
          WHERE hm.user_id = auth.uid()
        )
      );
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'diet_document'
      AND policyname = 'diet_document_delete_scope_guard'
  ) THEN
    CREATE POLICY diet_document_delete_scope_guard
      ON public.diet_document
      AS RESTRICTIVE
      FOR DELETE
      TO authenticated
      USING (
        user_id = auth.uid()
        AND household_id IN (
          SELECT hm.household_id
          FROM public.household_member hm
          WHERE hm.user_id = auth.uid()
        )
      );
  END IF;
END
$$;
