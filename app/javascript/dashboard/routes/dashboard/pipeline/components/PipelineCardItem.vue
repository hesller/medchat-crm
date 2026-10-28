<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import { formatValue } from '../helpers';

const props = defineProps({
  card: { type: Object, required: true },
});

defineEmits(['open']);

const { locale } = useI18n();

const formattedValue = computed(() =>
  props.card.value === null ? '' : formatValue(props.card.value, locale.value)
);
</script>

<template>
  <button
    type="button"
    class="flex flex-col w-full gap-2 p-3 text-start border rounded-lg cursor-grab bg-n-solid-1 border-n-weak hover:border-n-slate-6"
    @click="$emit('open', card)"
  >
    <span class="text-sm font-medium break-words text-n-slate-12">
      {{ card.title }}
    </span>
    <span v-if="formattedValue" class="text-sm font-medium text-n-teal-11">
      {{ formattedValue }}
    </span>
    <div
      v-if="card.contact || card.assignee"
      class="flex items-center justify-between w-full gap-2"
    >
      <span
        v-if="card.contact"
        class="flex items-center min-w-0 gap-1.5 text-xs text-n-slate-11"
      >
        <Avatar
          :name="card.contact.name"
          :src="card.contact.thumbnail"
          :size="16"
          rounded-full
        />
        <span class="truncate">{{ card.contact.name }}</span>
      </span>
      <Avatar
        v-if="card.assignee"
        v-tooltip="card.assignee.name"
        :name="card.assignee.name"
        :src="card.assignee.thumbnail"
        :size="20"
        rounded-full
        class="ms-auto"
      />
    </div>
  </button>
</template>
