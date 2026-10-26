<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  item: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['open', 'remove']);

const { t } = useI18n();

const conversation = computed(() => props.item.conversation);
const lastActivity = computed(() =>
  dynamicTime(conversation.value.last_activity_at)
);
</script>

<template>
  <li
    class="group flex flex-col gap-2 p-3 list-none border rounded-lg cursor-grab bg-n-solid-1 border-n-weak hover:border-n-slate-6"
    @click="emit('open', conversation.id)"
  >
    <div class="flex items-center gap-2 min-w-0">
      <Avatar
        :name="conversation.contact.name || ''"
        :src="conversation.contact.thumbnail"
        :size="24"
        rounded-full
      />
      <span class="flex-1 text-sm font-medium truncate text-n-slate-12">
        {{ conversation.contact.name }}
      </span>
      <Button
        icon="i-lucide-x"
        variant="ghost"
        color="slate"
        size="xs"
        class="invisible group-hover:visible"
        :title="t('PIPELINE.ACTIONS.REMOVE_CARD')"
        @click.stop="emit('remove', item)"
      />
    </div>
    <div class="flex items-center gap-2 text-xs text-n-slate-11">
      <span class="font-medium">#{{ conversation.id }}</span>
      <span class="truncate">{{ conversation.inbox_name }}</span>
      <span class="ms-auto shrink-0">{{ lastActivity }}</span>
    </div>
    <div class="flex items-center gap-1.5 text-xs text-n-slate-11">
      <template v-if="conversation.assignee">
        <Avatar
          :name="conversation.assignee.name"
          :src="conversation.assignee.thumbnail"
          :size="16"
          rounded-full
        />
        <span class="truncate">{{ conversation.assignee.name }}</span>
      </template>
      <span v-else>{{ t('PIPELINE.CARD.UNASSIGNED') }}</span>
    </div>
  </li>
</template>
