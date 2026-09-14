-- Demo-only access policies.
-- There is no staff authentication in version 1, so the publishable client
-- role must be able to use the application. Add authentication before using
-- this with real patient data.

create policy "Anyone can read doctors"
on public.doctors for select
to anon, authenticated
using (true);

create policy "Anyone can read patients"
on public.patients for select
to anon, authenticated
using (true);

create policy "Anyone can create patients"
on public.patients for insert
to anon, authenticated
with check (true);

create policy "Anyone can update patients"
on public.patients for update
to anon, authenticated
using (true)
with check (true);

create policy "Anyone can read appointments"
on public.appointments for select
to anon, authenticated
using (true);

create policy "Anyone can create appointments"
on public.appointments for insert
to anon, authenticated
with check (true);

create policy "Anyone can update appointments"
on public.appointments for update
to anon, authenticated
using (true)
with check (true);

create policy "Anyone can delete appointments"
on public.appointments for delete
to anon, authenticated
using (true);
