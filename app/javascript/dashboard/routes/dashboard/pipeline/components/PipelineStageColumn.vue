<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Draggable from 'vuedraggable';
import Button from 'dashboard/components-next/button/Button.vue';
import PipelineCardItem from './PipelineCardItem.vue';
import { formatValue, moveFromDragChange, stageTotal } from '../helpers';

const props = defineProps({
  stage: { type: Object, required: true },
  canManageStages: { type: Boolean, default: false },
});

const emit = defineEmits(['addCard', 'openCard', 'editStage', 'moveCard']);

const { t, locale } = useI18n();

const total = computed(() =>
  formatValue(stageTotal(props.stage.cards), locale.value)
);

const onChange = change => {
  const move = moveFromDragChange(change, props.stage.id);
  if (move) emit('moveCard', move);
};
</script>

<template>
  <section
    class="flex flex-col flex-shrink-0 w-72 max-h-full rounded-xl bg-n-alpha-1"
  >
    <header class="flex items-center gap-2 px-3 pt-3 pb-2">
      <span
        class="flex-shrink-0 rounded-full size-2.5"
        :style="{ backgroundColor: stage.color }"
      />
      <h3
        class="flex-1 min-w-0 text-sm font-medium truncate text-n-slate-12"
        :class="{ 'cursor-grab stage-handle': canManageStages }"
      >
        {{ stage.name }}
      </h3>
      <span class="text-xs text-n-slate-11">{{ stage.cards.length }}</span>
      <Button
        v-if="canManageStages"
        v-tooltip="t('PIPELINE.STAGE.EDIT')"
        icon="i-lucide-pencil"
        ghost
        slate
        xs
        @click="emit('editStage', stage)"
      />
    </header>
    <p class="px-3 pb-2 text-xs text-n-slate-11">
      {{ t('PIPELINE.STAGE.TOTAL', { total }) }}
    </p>
    <Draggable
      :list="stage.cards"
      group="pipeline-cards"
      item-key="id"
      class="flex flex-col flex-1 min-h-16 gap-2 px-3 pb-2 overflow-y-auto"
      ghost-class="opacity-40"
      @change="onChange"
    >
      <template #item="{ element }">
        <PipelineCardItem :card="element" @open="emit('openCard', $event)" />
      </template>
    </Draggable>
    <div class="px-3 pb-3">
      <Button
        :label="t('PIPELINE.STAGE.ADD_CARD')"
        icon="i-lucide-plus"
        ghost
        slate
        sm
        class="w-full"
        @click="emit('addCard', stage)"
      />
    </div>
  </section>
</template>
