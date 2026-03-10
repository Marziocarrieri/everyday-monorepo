-- Allow users to delete only their own household membership rows.
alter table if exists public.household_member enable row level security;

drop policy if exists household_member_delete_own on public.household_member;
create policy household_member_delete_own
on public.household_member
for delete
to authenticated
using (user_id = auth.uid());
