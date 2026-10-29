<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import { buildSettingsForm, buildSettingsPayload } from '../helpers';

const { t } = useI18n();
const store = useStore();
const { currentAccount } = useAccount();

const form = ref(buildSettingsForm(currentAccount.value?.settings));
const isSaving = ref(false);

watch(
  () => currentAccount.value?.settings,
  settings => {
    form.value = buildSettingsForm(settings);
  }
);

const save = async () => {
  isSaving.value = true;
  try {
    await store.dispatch('accounts/update', buildSettingsPayload(form.value));
    useAlert(t('WAITLIST.SETTINGS.SUCCESS'));
  } catch {
    useAlert(t('WAITLIST.SETTINGS.ERROR'));
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <form class="flex flex-col max-w-lg gap-5" @submit.prevent="save">
    <Input
      v-model="form.offerTimeoutMinutes"
      type="number"
      min="5"
      max="1440"
      :label="t('WAITLIST.SETTINGS.OFFER_TIMEOUT')"
      :message="t('WAITLIST.SETTINGS.OFFER_TIMEOUT_HELP')"
    />
    <Input
      v-model="form.entryValidityDays"
      type="number"
      min="1"
      max="365"
      :label="t('WAITLIST.SETTINGS.ENTRY_VALIDITY')"
      :message="t('WAITLIST.SETTINGS.ENTRY_VALIDITY_HELP')"
    />
    <div class="flex gap-4">
      <Input
        v-model="form.quietHoursStart"
        type="time"
        :label="t('WAITLIST.SETTINGS.QUIET_START')"
      />
      <Input
        v-model="form.quietHoursEnd"
        type="time"
        :label="t('WAITLIST.SETTINGS.QUIET_END')"
      />
    </div>
    <p class="text-sm text-n-slate-11">
      {{ t('WAITLIST.SETTINGS.QUIET_HELP') }}
    </p>
    <Button
      type="submit"
      :label="t('WAITLIST.SETTINGS.SAVE')"
      :is-loading="isSaving"
      class="self-start"
    />
  </form>
</template>
