<script setup>
import { ref, computed } from 'vue';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ColorPicker from 'dashboard/components-next/colorpicker/ColorPicker.vue';

defineProps({
  title: { type: String, required: true },
  description: { type: String, default: '' },
  nameLabel: { type: String, required: true },
  namePlaceholder: { type: String, default: '' },
  colorLabel: { type: String, default: '' },
  confirmLabel: { type: String, required: true },
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['confirm']);

const dialogRef = ref(null);
const name = ref('');
const color = ref('');

const isValid = computed(() => name.value.trim().length > 0);

const open = (values = {}) => {
  name.value = values.name || '';
  color.value = values.color || '#1f93ff';
  dialogRef.value.open();
};

const close = () => dialogRef.value.close();

const onConfirm = () => {
  if (!isValid.value) return;
  emit('confirm', { name: name.value.trim(), color: color.value });
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="title"
    :description="description"
    :confirm-button-label="confirmLabel"
    :disable-confirm-button="!isValid"
    :is-loading="isLoading"
    width="md"
    @confirm="onConfirm"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="name"
        :label="nameLabel"
        :placeholder="namePlaceholder"
        autofocus
      />
      <div v-if="colorLabel" class="flex flex-col gap-1">
        <span class="text-sm font-medium text-n-slate-12">
          {{ colorLabel }}
        </span>
        <ColorPicker v-model="color" />
      </div>
    </div>
  </Dialog>
</template>
