<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import EncaixesAPI from 'dashboard/api/encaixes';
import ContactAPI from 'dashboard/api/contacts';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const { t } = useI18n();

const dialogRef = ref(null);
const isSaving = ref(false);
const professional = ref(null);
const contacts = ref([]);
const contactId = ref('');
const startsAt = ref('');

const contactOptions = computed(() =>
  contacts.value.map(contact => ({
    value: contact.id,
    label: [contact.name, contact.phone_number].filter(Boolean).join(' · '),
  }))
);

const canSave = computed(() => !!contactId.value && !!startsAt.value);

const searchContacts = async query => {
  try {
    const { data } = await ContactAPI.search(query);
    contacts.value = data.payload;
  } catch {
    contacts.value = [];
  }
};

const open = existing => {
  professional.value = existing;
  contactId.value = '';
  startsAt.value = '';
  contacts.value = [];
  dialogRef.value?.open();
};

const submit = async () => {
  isSaving.value = true;
  try {
    await EncaixesAPI.create({
      professional_id: professional.value.id,
      contact_id: contactId.value,
      starts_at: new Date(startsAt.value).toISOString(),
    });
    useAlert(t('WAITLIST.ENCAIXE_FORM.SUCCESS'));
    dialogRef.value?.close();
  } catch (error) {
    useAlert(
      error.response?.data?.message || t('WAITLIST.ENCAIXE_FORM.ERROR')
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
    :title="
      t('WAITLIST.ENCAIXE_FORM.TITLE', { professional: professional?.name })
    "
    :description="t('WAITLIST.ENCAIXE_FORM.DESCRIPTION')"
    :confirm-button-label="t('WAITLIST.ENCAIXE_FORM.SAVE')"
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
      <Input
        v-model="startsAt"
        type="datetime-local"
        :label="t('WAITLIST.ENCAIXE_FORM.STARTS_AT')"
      />
    </div>
  </Dialog>
</template>
