<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDebounceFn } from '@vueuse/core';
import { useMapGetter } from 'dashboard/composables/store';
import ContactAPI from 'dashboard/api/contacts';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['submit', 'delete']);

const { t } = useI18n();

const DESCRIPTION_MAX_LENGTH = 5000;

const agents = useMapGetter('agents/getAgents');

const dialogRef = ref(null);
const card = ref(null);
const stageId = ref(null);
const form = ref({});
const contactName = ref('');
const contactOptions = ref([]);

const isEditing = computed(() => !!card.value);

const assigneeOptions = computed(() => [
  { value: '', label: t('PIPELINE.CARD_FORM.NO_ASSIGNEE') },
  ...agents.value.map(agent => ({ value: agent.id, label: agent.name })),
]);

const open = ({ card: existing = null, stageId: targetStageId }) => {
  card.value = existing;
  stageId.value = targetStageId;
  form.value = {
    title: existing?.title || '',
    value: existing?.value ?? '',
    description: existing?.description || '',
    contact_id: existing?.contact?.id || '',
    assignee_id: existing?.assignee?.id || '',
  };
  contactName.value = existing?.contact?.name || '';
  contactOptions.value = [];
  dialogRef.value?.open();
};

const close = () => dialogRef.value?.close();

const fetchContacts = async query => {
  try {
    const {
      data: { payload },
    } = query ? await ContactAPI.search(query) : await ContactAPI.get(1);
    contactOptions.value = payload.map(contact => ({
      value: contact.id,
      label: contact.name || contact.email || contact.phone_number,
    }));
  } catch {
    contactOptions.value = [];
  }
};

const searchContacts = useDebounceFn(
  query => fetchContacts(query?.trim()),
  300
);

const selectContact = value => {
  form.value.contact_id = value;
  contactName.value =
    contactOptions.value.find(option => option.value === value)?.label || '';
};

const submit = () => {
  if (!form.value.title.trim()) return;
  emit('submit', {
    card: card.value,
    attributes: {
      title: form.value.title.trim(),
      value: form.value.value === '' ? null : form.value.value,
      description: form.value.description,
      contact_id: form.value.contact_id || null,
      assignee_id: form.value.assignee_id || null,
      pipeline_stage_id: stageId.value,
    },
  });
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="
      isEditing
        ? t('PIPELINE.CARD_FORM.EDIT_TITLE')
        : t('PIPELINE.CARD_FORM.CREATE_TITLE')
    "
    :confirm-button-label="
      isEditing ? t('PIPELINE.CARD_FORM.SAVE') : t('PIPELINE.CARD_FORM.CREATE')
    "
    :disable-confirm-button="!form.title?.trim()"
    :is-loading="isLoading"
    width="lg"
    overflow-y-auto
    @confirm="submit"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="form.title"
        :label="t('PIPELINE.CARD_FORM.TITLE_LABEL')"
        :placeholder="t('PIPELINE.CARD_FORM.TITLE_PLACEHOLDER')"
        autofocus
      />
      <Input
        v-model="form.value"
        type="number"
        min="0"
        :label="t('PIPELINE.CARD_FORM.VALUE_LABEL')"
        :placeholder="t('PIPELINE.CARD_FORM.VALUE_PLACEHOLDER')"
      />
      <div class="flex flex-col gap-1">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('PIPELINE.CARD_FORM.CONTACT_LABEL') }}
        </span>
        <ComboBox
          :model-value="form.contact_id"
          :options="contactOptions"
          :display-label="contactName"
          :placeholder="t('PIPELINE.CARD_FORM.CONTACT_PLACEHOLDER')"
          :search-placeholder="t('PIPELINE.CARD_FORM.CONTACT_SEARCH')"
          use-api-results
          @open="fetchContacts('')"
          @search="searchContacts"
          @update:model-value="selectContact"
        />
      </div>
      <div class="flex flex-col gap-1">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('PIPELINE.CARD_FORM.ASSIGNEE_LABEL') }}
        </span>
        <ComboBox
          v-model="form.assignee_id"
          :options="assigneeOptions"
          :placeholder="t('PIPELINE.CARD_FORM.ASSIGNEE_PLACEHOLDER')"
        />
      </div>
      <TextArea
        v-model="form.description"
        :label="t('PIPELINE.CARD_FORM.DESCRIPTION_LABEL')"
        :placeholder="t('PIPELINE.CARD_FORM.DESCRIPTION_PLACEHOLDER')"
        :max-length="DESCRIPTION_MAX_LENGTH"
        auto-height
      />
      <Button
        v-if="isEditing"
        type="button"
        :label="t('PIPELINE.CARD_FORM.DELETE')"
        icon="i-lucide-trash-2"
        ghost
        ruby
        sm
        class="self-start"
        @click="emit('delete', card)"
      />
    </div>
  </Dialog>
</template>
