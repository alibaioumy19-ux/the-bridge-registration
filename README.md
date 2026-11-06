# The Bridge Events Platform

Reusable bilingual (English/Arabic) registration platform for university and career events.

## Stack
- React + Vite
- Supabase Auth + PostgreSQL + Row Level Security
- Deployable to Vercel or any static host

## Local setup
1. Install Node.js LTS if it is not already available.
2. Run `npm install`.
3. Copy `.env.example` to `.env`.
4. Add your Supabase project URL and anon key.
5. Run `npm run dev`.

## Database setup
1. Create a Supabase project.
2. Open SQL Editor and run `supabase/schema.sql`.
3. Create the initial admin user in Authentication.
4. Run the Super Admin promotion SQL at the bottom of the schema, replacing the email.
5. Add a published event record. Use the event slug as the public form path, e.g. `/?event=from-campus-to-career`.

## Admin
Open `/admin` and sign in with the Supabase Auth account. The initial role is granted through the SQL promotion step.

## Decisions
- One platform supports multiple events.
- Registrations are unlimited at the application level.
- Approval mode is configured per event: automatic or manual.
- English and Arabic UI.
- One Super Admin initially.
- No domain is required for development.
- Never commit real Supabase keys to Git.

## Current implementation scope
- Public event registration page
- Event-specific fields from database JSON
- Duplicate email protection per event
- Registration reference generation
- Automatic confirmation / manual pending status
- Admin sign-in, registration table, status updates, CSV export

Before public launch, add email confirmation delivery, rate limiting / CAPTCHA, admin event CRUD, and production deployment configuration.
