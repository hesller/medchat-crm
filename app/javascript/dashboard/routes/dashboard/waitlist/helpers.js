export const WAITLIST_TABS = ['QUEUE', 'PROFESSIONALS', 'SETTINGS'];

export const DEFAULT_OFFER_TIMEOUT_MINUTES = 30;
export const DEFAULT_ENTRY_VALIDITY_DAYS = 30;

export const OPEN_STATUSES = ['waiting', 'offered'];

// Mirrors the settings the account falls back to when none was saved.
export const buildSettingsForm = settings => ({
  offerTimeoutMinutes:
    settings?.waitlist_offer_timeout_minutes ?? DEFAULT_OFFER_TIMEOUT_MINUTES,
  entryValidityDays:
    settings?.waitlist_entry_validity_days ?? DEFAULT_ENTRY_VALIDITY_DAYS,
  quietHoursStart: settings?.waitlist_quiet_hours_start || '',
  quietHoursEnd: settings?.waitlist_quiet_hours_end || '',
});

export const buildSettingsPayload = form => ({
  waitlist_offer_timeout_minutes: Number(form.offerTimeoutMinutes),
  waitlist_entry_validity_days: Number(form.entryValidityDays),
  waitlist_quiet_hours_start: form.quietHoursStart || null,
  waitlist_quiet_hours_end: form.quietHoursEnd || null,
});
