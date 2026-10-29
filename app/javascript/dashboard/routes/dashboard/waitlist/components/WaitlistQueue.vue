<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import WaitlistEntriesAPI from 'dashboard/api/waitlistEntries';
import { dynamicTime } from 'shared/helpers/timeHelper';

import Button from 'dashboard/components-next/button/Button.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import WaitlistEntryDialog from './WaitlistEntryDialog.vue';
import { OPEN_STATUSES } from '../helpers';

const { t } = useI18n();

const entries = ref([]);
const isLoading = ref(false);
const status = ref('open');
const entryDialogRef = ref(null);

const statusOptions = computed(() =>
  ['open', 'waiting', 'offered', 'scheduled', 'expired', 'cancelled'].map(
    value => ({ value, label: t(`WAITLIST.STATUS.${value.toUpperCase()}`) })
  )
);

const visibleEntries = computed(() =>
  status.value === 'open'
    ? entries.value.filter(entry => OPEN_STATUSES.includes(entry.status))
    : entries.value.filter(entry => entry.status === status.value)
);

const load = async () => {
  isLoading.value = true;
  try {
    const { data } = await WaitlistEntriesAPI.list();
    entries.value = data.payload;
  } catch {
    useAlert(t('WAITLIST.MESSAGES.LOAD_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const cancelEntry = async entry => {
  try {
    await WaitlistEntriesAPI.delete(entry.id);
    entry.status = 'cancelled';
  } catch {
    useAlert(t('WAITLIST.MESSAGES.CANCEL_ERROR'));
  }
};

const requestedLabel = entry =>
  entry.professional
    ? `${entry.professional.name} · ${entry.specialty}`
    : t('WAITLIST.QUEUE.ANY_PROFESSIONAL', { specialty: entry.specialty });

const offerLabel = entry =>
  t('WAITLIST.QUEUE.OFFER_SUMMARY', {
    professional: entry.offer.professional.name,
    slot: new Date(entry.offer.slot_starts_at).toLocaleString(),
  });

onMounted(load);
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex items-center gap-3">
      <Select
        v-model="status"
        :options="statusOptions"
        :aria-label="t('WAITLIST.QUEUE.FILTER')"
      />
      <Button
        :label="t('WAITLIST.QUEUE.ADD')"
        icon="i-lucide-plus"
        sm
        class="ms-auto"
        @click="entryDialogRef.open()"
      />
    </div>

    <div v-if="isLoading" class="flex items-center justify-center py-12">
      <Spinner />
    </div>
    <p
      v-else-if="!visibleEntries.length"
      class="py-12 text-sm text-center text-n-slate-11"
    >
      {{ t('WAITLIST.QUEUE.EMPTY') }}
    </p>
    <ul v-else class="flex flex-col divide-y divide-n-weak">
      <li
        v-for="entry in visibleEntries"
        :key="entry.id"
        class="flex flex-wrap items-center gap-3 py-3"
      >
        <div class="flex flex-col min-w-0 gap-0.5">
          <span class="text-sm font-medium text-n-slate-12">
            {{ entry.contact.name }}
            <span class="font-normal text-n-slate-11">
              {{ entry.contact.phone_number }}
            </span>
          </span>
          <span class="text-sm text-n-slate-11">{{
            requestedLabel(entry)
          }}</span>
          <span v-if="entry.offer" class="text-sm text-n-teal-11">
            {{ offerLabel(entry) }}
          </span>
        </div>
        <span class="text-xs text-n-slate-11 ms-auto">
          {{ t(`WAITLIST.STATUS.${entry.status.toUpperCase()}`) }}
          · {{ dynamicTime(new Date(entry.created_at).getTime() / 1000) }}
        </span>
        <Button
          v-if="OPEN_STATUSES.includes(entry.status)"
          :label="t('WAITLIST.QUEUE.CANCEL')"
          icon="i-lucide-x"
          ghost
          ruby
          sm
          @click="cancelEntry(entry)"
        />
      </li>
    </ul>

    <WaitlistEntryDialog ref="entryDialogRef" @saved="load" />
  </div>
</template>
