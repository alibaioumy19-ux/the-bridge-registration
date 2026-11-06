import { createClient } from '@supabase/supabase-js';

const url = import.meta.env.VITE_SUPABASE_URL;
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
export const isConfigured = Boolean(url && anonKey);
export const supabase = isConfigured ? createClient(url, anonKey) : null;

export async function getActiveEvent(slug) {
  if (!supabase) return null;
  const { data, error } = await supabase
    .from('events')
    .select('*')
    .eq('slug', slug)
    .eq('is_published', true)
    .single();
  if (error) throw error;
  return data;
}

export async function sendRegistrationEmail(registrationCode) {
  if (!supabase) throw new Error('The database is not connected.');
  const { error } = await supabase.functions.invoke('send-registration-email', {
    body: { registration_code: registrationCode }
  });
  if (error) throw error;
}

export async function submitRegistration(event, form) {
  if (!supabase) throw new Error('The database is not connected yet. Add your Supabase project URL and anon key to the .env file.');
  const registrationCode = `TB-${new Date().getFullYear()}-${crypto.randomUUID().slice(0, 8).toUpperCase()}`;
  const { data, error } = await supabase.from('registrations').insert({
    event_id: event.id,
    registration_code: registrationCode,
    full_name: form.fullName.trim(),
    email: form.email.trim().toLowerCase(),
    phone: form.phone.trim(),
    university: form.university.trim(),
    faculty: form.faculty.trim() || null,
    academic_year: form.academicYear || null,
    answers: { ...form.extra }
  });
  if (error) {
    if (error.code === '23505') throw new Error('This email is already registered for this event.');
    throw error;
  }

  const status = event.approval_mode === 'manual' ? 'pending' : 'confirmed';
  await sendRegistrationEmail(registrationCode);
  return { registration_code: registrationCode, status };
}
