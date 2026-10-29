<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import ProfessionalsAPI from 'dashboard/api/professionals';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const emit = defineEmits(['saved']);

const { t } = useI18n();

const dialogRef = ref(null);
const isSaving = ref(false);
const professional = ref(null);
const name = ref('');
const specialty = ref('');
const externalCalendarId = ref('');
const encaixeDailyLimit = ref('');
const active = ref(true);

const isEditing = computed(() => !!professional.value);
const canSave = computed(() => !!name.value.trim() && !!specialty.value.trim());

const open = (existing = null) => {
  professional.value = existing;
  name.value = existing?.name || '';
  specialty.value = existing?.specialty || '';
  externalCalendarId.value = existing?.external_calendar_id || '';
  encaixeDailyLimit.value = existing?.encaixe_daily_limit ?? '';
  active.value = existing ? existing.active : true;
  dialogRef.value?.open();
};

const submit = async () => {
  isSaving.value = true;
  const attributes = {
    name: name.value.trim(),
    specialty: specialty.value.trim(),
    external_calendar_id: externalCalendarId.value.trim() || null,
    encaixe_daily_limit:
      encaixeDailyLimit.value === '' ? null : Number(encaixeDailyLimit.value),
    active: active.value,
  };
  try {
    if (isEditing.value) {
      await ProfessionalsAPI.update(professional.value.id, {
        professional: attributes,
      });
    } else {
      await ProfessionalsAPI.create({ professional: attributes });
    }
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
    :title="
      isEditing
        ? t('WAITLIST.PROFESSIONAL_FORM.EDIT_TITLE')
        : t('WAITLIST.PROFESSIONAL_FORM.CREATE_TITLE')
    "
    :confirm-button-label="t('WAITLIST.PROFESSIONAL_FORM.SAVE')"
    :disable-confirm-button="!canSave"
    :is-loading="isSaving"
    width="md"
    @confirm="submit"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="name"
        :label="t('WAITLIST.PROFESSIONAL_FORM.NAME')"
        autofocus
      />
      <Input
        v-model="specialty"
        :label="t('WAITLIST.PROFESSIONAL_FORM.SPECIALTY')"
      />
      <Input
        v-model="externalCalendarId"
        :label="t('WAITLIST.PROFESSIONAL_FORM.CALENDAR_ID')"
        :message="t('WAITLIST.PROFESSIONAL_FORM.CALENDAR_ID_HELP')"
      />
      <Input
        v-model="encaixeDailyLimit"
        type="number"
        min="0"
        :label="t('WAITLIST.PROFESSIONAL_FORM.ENCAIXE_LIMIT')"
        :message="t('WAITLIST.PROFESSIONAL_FORM.ENCAIXE_LIMIT_HELP')"
      />
      <label class="flex items-center gap-2 text-sm text-n-slate-12">
        <Switch v-model="active" />
        {{ t('WAITLIST.PROFESSIONAL_FORM.ACTIVE') }}
      </label>
    </div>
  </Dialog>
</template>
