# HabitTracker Web

A web remake of the bundled macOS HabitTracker app. It mirrors the dark UI, habit list, pie chart view, and supports real-time sync across devices via Supabase (free tier) and can be deployed on Netlify.

## Tech stack
- React 18 + Vite + TypeScript
- Supabase (Postgres + Auth + Realtime)
- Netlify for hosting

## Prerequisites
- Node.js 18+ and npm
- A Supabase project (free tier is fine)
- A Netlify account (optional for local use; required to host)

## Supabase setup

1) **Create table**
   Run this SQL in Supabase SQL editor:

   ```sql
   create table public.habits (
     id uuid primary key default gen_random_uuid(),
     user_id uuid not null references auth.users(id) on delete cascade,
     name text not null,
     color text default '#007AFF',
     completions text[] default '{}', -- array of yyyy-MM-dd strings
     created_at timestamptz not null default now()
   );

   alter table public.habits enable row level security;
   ```

2) **Row Level Security (required)**  
   Add these policies to scope data to the logged-in user:

   ```sql
   create policy "Individuals can select their habits"
     on public.habits for select
     using (auth.uid() = user_id);

   create policy "Individuals can insert their habits"
     on public.habits for insert
     with check (auth.uid() = user_id);

   create policy "Individuals can update their habits"
     on public.habits for update
     using (auth.uid() = user_id)
     with check (auth.uid() = user_id);

   create policy "Individuals can delete their habits"
     on public.habits for delete
     using (auth.uid() = user_id);
   ```

3) **Auth**  
   - Enable Email OTP/Magic Link (no password) in Supabase Authentication settings.
   - Optionally set a custom SMTP sender; otherwise use the Supabase defaults.

4) **Environment variables**  
   From your Supabase project settings, grab:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
   And set the site URL used for magic link redirects:
   - `VITE_SITE_URL` (e.g. your Netlify URL like https://your-site.netlify.app; dev falls back to window.location.origin)

## Local development

1) Install deps:
   ```bash
   npm install
   ```

2) Create `HabitTracker/web/.env` (or `.env.local`) with:
   ```
   VITE_SUPABASE_URL=your-supabase-url
   VITE_SUPABASE_ANON_KEY=your-supabase-anon-key
   ```

3) Run dev server:
   ```bash
   npm run dev
   ```
   Open the shown URL (defaults to http://localhost:5173).

4) Build for production:
   ```bash
   npm run build
   ```

## Usage notes
- Sign in with your email; a magic link will authenticate you.
- Add habits, toggle today’s completion, switch between list and chart, and select time ranges (day/week/month/year). Data is scoped to your Supabase user and syncs in real time across devices.

## Deploy to Netlify (free tier)

1) **Repo & project**
   - Push this `HabitTracker/web` folder to your repo.
   - In Netlify, “Add new site” → “Import from Git”.

2) **Build settings**
   - Base directory: `HabitTracker/web`
   - Build command: `npm run build`
   - Publish directory: `HabitTracker/web/dist`

3) **Environment variables (Netlify UI)**  
   - `VITE_SUPABASE_URL`  
   - `VITE_SUPABASE_ANON_KEY`  
   - `VITE_SITE_URL` (your Netlify site URL for magic link redirects)

4) **Deploy**
   - Trigger a deploy. Netlify will build and host your site at your chosen domain.

5) **Mobile access**
   - Open the Netlify URL on your phone. All devices share the same Supabase backend, so habits and completion states stay in sync.

## Troubleshooting
- **Magic link not arriving**: Check spam or set a custom SMTP in Supabase.
- **403/401 errors**: Confirm RLS policies and that `user_id` is enforced by the policies above.
- **No data after login**: Ensure environment variables are set in both local `.env` and Netlify dashboard.
- **Realtime not updating**: Verify the Supabase anon key and that “Enable Realtime” is on for the `habits` table.

## Project scripts
- `npm run dev` — start Vite dev server
- `npm run build` — production build
- `npm run preview` — preview the production build locally