<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ColorPicker from 'dashboard/components-next/colorpicker/ColorPicker.vue';
import { DEFAULT_STAGE_COLOR } from '../helpers';

defineProps({
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['submit', 'delete']);

const { t } = useI18n();

const dialogRef = ref(null);
const stage = ref(null);
const name = ref('');
const color = ref(DEFAULT_STAGE_COLOR);

const isEditing = computed(() => !!stage.value);

const open = (existing = null) => {
  stage.value = existing;
  name.value = existing?.name || '';
  color.value = existing?.color || DEFAULT_STAGE_COLOR;
  dialogRef.value?.open();
};

const close = () => dialogRef.value?.close();

const submit = () => {
  if (!name.value.trim()) return;
  emit('submit', {
    stage: stage.value,
    attributes: { name: name.value.trim(), color: color.value.toUpperCase() },
  });
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="
      isEditing
        ? t('PIPELINE.STAGE_FORM.EDIT_TITLE')
        : t('PIPELINE.STAGE_FORM.CREATE_TITLE')
    "
    :confirm-button-label="
      isEditing
        ? t('PIPELINE.STAGE_FORM.SAVE')
        : t('PIPELINE.STAGE_FORM.CREATE')
    "
    :disable-confirm-button="!name.trim()"
    :is-loading="isLoading"
    width="md"
    overflow-y-auto
    @confirm="submit"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="name"
        :label="t('PIPELINE.STAGE_FORM.NAME_LABEL')"
        :placeholder="t('PIPELINE.STAGE_FORM.NAME_PLACEHOLDER')"
        autofocus
      />
      <div class="flex flex-col gap-1">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('PIPELINE.STAGE_FORM.COLOR_LABEL') }}
        </span>
        <ColorPicker v-model="color" />
      </div>
      <Button
        v-if="isEditing"
        type="button"
        :label="t('PIPELINE.STAGE_FORM.DELETE')"
        icon="i-lucide-trash-2"
        ghost
        ruby
        sm
        class="self-start"
        @click="emit('delete', stage)"
      />
    </div>
  </Dialog>
</template>
