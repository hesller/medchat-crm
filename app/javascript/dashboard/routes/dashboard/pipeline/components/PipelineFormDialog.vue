<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { DEFAULT_STAGES } from '../helpers';

defineProps({
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['submit', 'delete']);

const { t } = useI18n();

const dialogRef = ref(null);
const pipeline = ref(null);
const name = ref('');

const isEditing = computed(() => !!pipeline.value);

const open = (existing = null) => {
  pipeline.value = existing;
  name.value = existing?.name || '';
  dialogRef.value?.open();
};

const close = () => dialogRef.value?.close();

const submit = () => {
  if (!name.value.trim()) return;

  const attributes = { name: name.value.trim() };
  // A new pipeline starts with the usual sales stages, which can be edited later.
  if (!isEditing.value) {
    attributes.stages_attributes = DEFAULT_STAGES.map(({ key, color }) => ({
      name: t(`PIPELINE.PIPELINE_FORM.DEFAULT_STAGES.${key}`),
      color,
    }));
  }
  emit('submit', { pipeline: pipeline.value, attributes });
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="
      isEditing
        ? t('PIPELINE.PIPELINE_FORM.EDIT_TITLE')
        : t('PIPELINE.PIPELINE_FORM.CREATE_TITLE')
    "
    :description="isEditing ? '' : t('PIPELINE.PIPELINE_FORM.DESCRIPTION')"
    :confirm-button-label="
      isEditing
        ? t('PIPELINE.PIPELINE_FORM.SAVE')
        : t('PIPELINE.PIPELINE_FORM.CREATE')
    "
    :disable-confirm-button="!name.trim()"
    :is-loading="isLoading"
    width="md"
    @confirm="submit"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="name"
        :label="t('PIPELINE.PIPELINE_FORM.NAME_LABEL')"
        :placeholder="t('PIPELINE.PIPELINE_FORM.NAME_PLACEHOLDER')"
        autofocus
      />
      <Button
        v-if="isEditing"
        type="button"
        :label="t('PIPELINE.PIPELINE_FORM.DELETE')"
        icon="i-lucide-trash-2"
        ghost
        ruby
        sm
        class="self-start"
        @click="emit('delete', pipeline)"
      />
    </div>
  </Dialog>
</template>
