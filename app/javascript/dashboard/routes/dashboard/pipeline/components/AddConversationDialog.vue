<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';
import SearchAPI from 'dashboard/api/search';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  existingConversationIds: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['select']);

const { t } = useI18n();

const dialogRef = ref(null);
const query = ref('');
const results = ref([]);
const hasSearched = ref(false);

const search = debounce(async () => {
  if (!query.value.trim()) {
    results.value = [];
    hasSearched.value = false;
    return;
  }
  const { data } = await SearchAPI.conversations({ q: query.value.trim() });
  results.value = data.payload?.conversations || [];
  hasSearched.value = true;
}, 300);

const isAdded = conversation =>
  props.existingConversationIds.includes(conversation.id);

const open = () => {
  query.value = '';
  results.value = [];
  hasSearched.value = false;
  dialogRef.value.open();
};

const close = () => dialogRef.value.close();

const select = conversation => {
  if (isAdded(conversation)) return;
  emit('select', conversation.id);
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('PIPELINE.ADD_CONVERSATION.TITLE')"
    :description="t('PIPELINE.ADD_CONVERSATION.DESCRIPTION')"
    :show-confirm-button="false"
    width="md"
  >
    <div class="flex flex-col gap-3">
      <Input
        v-model="query"
        :placeholder="t('PIPELINE.ADD_CONVERSATION.SEARCH_PLACEHOLDER')"
        autofocus
        @input="search"
      />
      <ul class="flex flex-col gap-1 max-h-80 overflow-y-auto">
        <li
          v-for="conversation in results"
          :key="conversation.id"
          class="flex items-center gap-2 px-2 py-2 list-none rounded-lg"
          :class="
            isAdded(conversation)
              ? 'opacity-60 cursor-not-allowed'
              : 'cursor-pointer hover:bg-n-alpha-2'
          "
          @click="select(conversation)"
        >
          <Avatar
            :name="conversation.contact?.name || ''"
            :src="conversation.contact?.thumbnail"
            :size="24"
            rounded-full
          />
          <span class="flex-1 text-sm truncate text-n-slate-12">
            {{ conversation.contact?.name }}
          </span>
          <span class="text-xs text-n-slate-11">
            {{
              isAdded(conversation)
                ? t('PIPELINE.ADD_CONVERSATION.ALREADY_ADDED')
                : `#${conversation.id}`
            }}
          </span>
        </li>
      </ul>
      <p
        v-if="hasSearched && !results.length"
        class="mb-0 text-sm text-center text-n-slate-11"
      >
        {{ t('PIPELINE.ADD_CONVERSATION.NO_RESULTS') }}
      </p>
    </div>
  </Dialog>
</template>
