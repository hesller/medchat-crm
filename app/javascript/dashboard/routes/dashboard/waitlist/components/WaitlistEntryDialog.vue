<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import WaitlistEntriesAPI from 'dashboard/api/waitlistEntries';
import ProfessionalsAPI from 'dashboard/api/professionals';
import ContactAPI from 'dashboard/api/contacts';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const emit = defineEmits(['saved']);

const { t } = useI18n();

const dialogRef = ref(null);
const isSaving = ref(false);
const professionals = ref([]);
const contacts = ref([]);
const contactId = ref('');
const professionalId = ref('');
const specialty = ref('');

const ANY_PROFESSIONAL = '';

const specialties = computed(() => [
  ...new Set(professionals.value.map(professional => professional.specialty)),
]);

const specialtyOptions = computed(() =>
  specialties.value.map(value => ({ value, label: value }))
);

const professionalOptions = computed(() => [
  { value: ANY_PROFESSIONAL, label: t('WAITLIST.ENTRY_FORM.ANY_PROFESSIONAL') },
  ...professionals.value
    .filter(professional => professional.specialty === specialty.value)
    .map(professional => ({
      value: professional.id,
      label: professional.name,
    })),
]);

const contactOptions = computed(() =>
  contacts.value.map(contact => ({
    value: contact.id,
    label: [contact.name, contact.phone_number].filter(Boolean).join(' · '),
  }))
);

const canSave = computed(() => !!contactId.value && !!specialty.value);

const searchContacts = async query => {
  try {
    const { data } = await ContactAPI.search(query);
    contacts.value = data.payload;
  } catch {
    contacts.value = [];
  }
};

const open = async () => {
  contactId.value = '';
  professionalId.value = ANY_PROFESSIONAL;
  specialty.value = '';
  contacts.value = [];
  dialogRef.value?.open();
  try {
    const { data } = await ProfessionalsAPI.get();
    professionals.value = data.payload.filter(
      professional => professional.active
    );
  } catch {
    useAlert(t('WAITLIST.MESSAGES.LOAD_ERROR'));
  }
};

const submit = async () => {
  isSaving.value = true;
  try {
    await WaitlistEntriesAPI.create({
      waitlist_entry: {
        contact_id: contactId.value,
        specialty: specialty.value,
        professional_id: professionalId.value || null,
      },
    });
    dialogRef.value?.close();
    emit('saved');
  } catch (error) {
    useAlert(
      error.response?.data?.message || t('WAITLIST.MESSAGES.SAVE_ERROR')
    );
  } finally {
    isSaving.value = false;
  }
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('WAITLIST.ENTRY_FORM.TITLE')"
    :description="t('WAITLIST.ENTRY_FORM.DESCRIPTION')"
    :confirm-button-label="t('WAITLIST.ENTRY_FORM.SAVE')"
    :disable-confirm-button="!canSave"
    :is-loading="isSaving"
    width="md"
    @confirm="submit"
  >
    <div class="flex flex-col gap-4">
      <ComboBox
        v-model="contactId"
        use-api-results
        :options="contactOptions"
        :placeholder="t('WAITLIST.ENTRY_FORM.CONTACT')"
        :search-placeholder="t('WAITLIST.ENTRY_FORM.CONTACT_SEARCH')"
        @search="searchContacts"
      />
      <ComboBox
        v-model="specialty"
        :options="specialtyOptions"
        :placeholder="t('WAITLIST.ENTRY_FORM.SPECIALTY')"
        :empty-state="t('WAITLIST.ENTRY_FORM.NO_PROFESSIONALS')"
      />
      <ComboBox
        v-if="specialty"
        v-model="professionalId"
        :options="professionalOptions"
        :placeholder="t('WAITLIST.ENTRY_FORM.PROFESSIONAL')"
      />
    </div>
  </Dialog>
</template>
