import {
  buildSettingsForm,
  buildSettingsPayload,
  DEFAULT_ENTRY_VALIDITY_DAYS,
  DEFAULT_OFFER_TIMEOUT_MINUTES,
} from '../helpers';

describe('waitlist helpers', () => {
  describe('buildSettingsForm', () => {
    it('falls back to the defaults when the account saved nothing', () => {
      expect(buildSettingsForm({})).toEqual({
        offerTimeoutMinutes: DEFAULT_OFFER_TIMEOUT_MINUTES,
        entryValidityDays: DEFAULT_ENTRY_VALIDITY_DAYS,
        quietHoursStart: '',
        quietHoursEnd: '',
      });
    });

    it('reads the saved settings', () => {
      const form = buildSettingsForm({
        waitlist_offer_timeout_minutes: 45,
        waitlist_entry_validity_days: 10,
        waitlist_quiet_hours_start: '20:00',
        waitlist_quiet_hours_end: '08:00',
      });

      expect(form).toEqual({
        offerTimeoutMinutes: 45,
        entryValidityDays: 10,
        quietHoursStart: '20:00',
        quietHoursEnd: '08:00',
      });
    });
  });

  describe('buildSettingsPayload', () => {
    it('sends numbers as numbers and empty quiet hours as null', () => {
      const payload = buildSettingsPayload({
        offerTimeoutMinutes: '45',
        entryValidityDays: '10',
        quietHoursStart: '',
        quietHoursEnd: '',
      });

      expect(payload).toEqual({
        waitlist_offer_timeout_minutes: 45,
        waitlist_entry_validity_days: 10,
        waitlist_quiet_hours_start: null,
        waitlist_quiet_hours_end: null,
      });
    });
  });
});
