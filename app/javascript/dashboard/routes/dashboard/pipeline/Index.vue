<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import Draggable from 'vuedraggable';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import PipelinesAPI from 'dashboard/api/pipelines';

import Button from 'dashboard/components-next/button/Button.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import PipelineStageColumn from './components/PipelineStageColumn.vue';
import PipelineFormDialog from './components/PipelineFormDialog.vue';
import PipelineStageDialog from './components/PipelineStageDialog.vue';
import PipelineCardDialog from './components/PipelineCardDialog.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();
const { currentAccount } = useAccount();
const { isAdmin } = useAdmin();

const isEnabled = computed(
  () => !!currentAccount.value?.settings?.pipeline_enabled
);

const pipelines = ref([]);
const board = ref(null);
const isLoading = ref(false);
const isSaving = ref(false);

const pipelineFormRef = ref(null);
const stageDialogRef = ref(null);
const cardDialogRef = ref(null);
const confirmDialogRef = ref(null);
const confirmation = ref({ title: '', description: '', onConfirm: null });

const selectedPipelineId = computed(() => Number(route.query.pipelineId));

const pipelineOptions = computed(() =>
  pipelines.value.map(pipeline => ({
    value: pipeline.id,
    label: pipeline.name,
  }))
);

const selectPipeline = id => {
  router.replace({ query: { ...route.query, pipelineId: id || undefined } });
};

const selectedPipeline = computed({
  get: () => selectedPipelineId.value || '',
  set: id => selectPipeline(Number(id)),
});

const loadBoard = async id => {
  if (!id) {
    board.value = null;
    return;
  }
  isLoading.value = true;
  try {
    const { data } = await PipelinesAPI.show(id);
    board.value = data.payload;
  } catch {
    board.value = null;
    useAlert(t('PIPELINE.MESSAGES.LOAD_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const loadPipelines = async () => {
  isLoading.value = true;
  try {
    const { data } = await PipelinesAPI.get();
    pipelines.value = data.payload;
  } catch {
    pipelines.value = [];
    useAlert(t('PIPELINE.MESSAGES.LOAD_ERROR'));
  } finally {
    isLoading.value = false;
  }

  const exists = pipelines.value.some(p => p.id === selectedPipelineId.value);
  if (!exists) {
    selectPipeline(pipelines.value[0]?.id);
  } else {
    loadBoard(selectedPipelineId.value);
  }
};

watch(selectedPipelineId, id => {
  if (board.value?.id !== id) loadBoard(id);
});

// The account (and its settings) may still be loading when this page opens
// straight from a link, so wait for the flag instead of reading it once.
watch(
  isEnabled,
  enabled => {
    if (!enabled) return;
    store.dispatch('agents/get');
    loadPipelines();
  },
  { immediate: true }
);

const runSaving = async (
  request,
  errorKey = 'PIPELINE.MESSAGES.SAVE_ERROR'
) => {
  isSaving.value = true;
  try {
    return await request();
  } catch {
    useAlert(t(errorKey));
    return null;
  } finally {
    isSaving.value = false;
  }
};

const askConfirmation = ({ title, description, onConfirm }) => {
  confirmation.value = { title, description, onConfirm };
  confirmDialogRef.value?.open();
};

const confirm = async () => {
  await confirmation.value.onConfirm();
  confirmDialogRef.value?.close();
};

const savePipeline = async ({ pipeline, attributes }) => {
  const response = await runSaving(() =>
    pipeline
      ? PipelinesAPI.update(pipeline.id, { pipeline: attributes })
      : PipelinesAPI.create({ pipeline: attributes })
  );
  if (!response) return;

  pipelineFormRef.value?.close();
  const saved = response.data.payload;
  if (pipeline) {
    board.value.name = saved.name;
    pipelines.value = pipelines.value.map(p => (p.id === saved.id ? saved : p));
    return;
  }
  pipelines.value = [...pipelines.value, saved];
  selectPipeline(saved.id);
};

const deletePipeline = pipeline => {
  pipelineFormRef.value?.close();
  askConfirmation({
    title: t('PIPELINE.PIPELINE_FORM.DELETE_CONFIRM_TITLE'),
    description: t('PIPELINE.PIPELINE_FORM.DELETE_CONFIRM_DESCRIPTION', {
      name: pipeline.name,
    }),
    onConfirm: async () => {
      const response = await runSaving(
        () => PipelinesAPI.delete(pipeline.id),
        'PIPELINE.MESSAGES.DELETE_ERROR'
      );
      if (!response) return;
      pipelines.value = pipelines.value.filter(p => p.id !== pipeline.id);
      board.value = null;
      selectPipeline(pipelines.value[0]?.id);
    },
  });
};

const saveStage = async ({ stage, attributes }) => {
  const pipelineId = board.value.id;
  const response = await runSaving(() =>
    stage
      ? PipelinesAPI.updateStage(pipelineId, stage.id, attributes)
      : PipelinesAPI.createStage(pipelineId, attributes)
  );
  if (!response) return;

  stageDialogRef.value?.close();
  const saved = response.data.payload;
  if (stage) {
    Object.assign(stage, { name: saved.name, color: saved.color });
  } else {
    board.value.stages.push({ ...saved, cards: [] });
  }
};

const deleteStage = stage => {
  stageDialogRef.value?.close();
  askConfirmation({
    title: t('PIPELINE.STAGE_FORM.DELETE_CONFIRM_TITLE'),
    description: t('PIPELINE.STAGE_FORM.DELETE_CONFIRM_DESCRIPTION', {
      name: stage.name,
      count: stage.cards.length,
    }),
    onConfirm: async () => {
      const response = await runSaving(
        () => PipelinesAPI.deleteStage(board.value.id, stage.id),
        'PIPELINE.MESSAGES.DELETE_ERROR'
      );
      if (!response) return;
      board.value.stages = board.value.stages.filter(s => s.id !== stage.id);
    },
  });
};

const reorderStages = async () => {
  const ids = board.value.stages.map(stage => stage.id);
  try {
    await PipelinesAPI.reorderStages(board.value.id, ids);
  } catch {
    useAlert(t('PIPELINE.MESSAGES.MOVE_ERROR'));
    loadBoard(board.value.id);
  }
};

const findStage = id => board.value.stages.find(stage => stage.id === id);

const saveCard = async ({ card, attributes }) => {
  const pipelineId = board.value.id;
  const { pipeline_stage_id: stageId, ...changes } = attributes;
  const response = await runSaving(() =>
    card
      ? PipelinesAPI.updateCard(pipelineId, card.id, changes)
      : PipelinesAPI.createCard(pipelineId, attributes)
  );
  if (!response) return;

  cardDialogRef.value?.close();
  const saved = response.data.payload;
  const stage = findStage(saved.pipeline_stage_id);
  if (card) {
    stage.cards = stage.cards.map(c => (c.id === saved.id ? saved : c));
  } else {
    findStage(stageId).cards.push(saved);
  }
};

const deleteCard = card => {
  cardDialogRef.value?.close();
  askConfirmation({
    title: t('PIPELINE.CARD_FORM.DELETE_CONFIRM_TITLE'),
    description: t('PIPELINE.CARD_FORM.DELETE_CONFIRM_DESCRIPTION', {
      title: card.title,
    }),
    onConfirm: async () => {
      const response = await runSaving(
        () => PipelinesAPI.deleteCard(board.value.id, card.id),
        'PIPELINE.MESSAGES.DELETE_ERROR'
      );
      if (!response) return;
      const stage = findStage(card.pipeline_stage_id);
      stage.cards = stage.cards.filter(c => c.id !== card.id);
    },
  });
};

// The board already shows the card in its new place; the server only needs
// to agree. When it does not, the board is reloaded to show what was stored.
const moveCard = async ({ card, stageId, position }) => {
  try {
    const { data } = await PipelinesAPI.moveCard(board.value.id, card.id, {
      stageId,
      position,
    });
    card.pipeline_stage_id = data.payload.pipeline_stage_id;
  } catch {
    useAlert(t('PIPELINE.MESSAGES.MOVE_ERROR'));
    loadBoard(board.value.id);
  }
};
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <div
      v-if="!isEnabled"
      class="flex flex-col items-center justify-center flex-1 gap-2 px-6 text-center"
    >
      <h2 class="text-base font-medium text-n-slate-12">
        {{ t('PIPELINE.DISABLED.TITLE') }}
      </h2>
      <p class="max-w-md text-sm text-n-slate-11">
        {{ t('PIPELINE.DISABLED.DESCRIPTION') }}
      </p>
    </div>
    <template v-else>
      <header
        class="flex flex-wrap items-center gap-3 px-6 py-4 border-b border-n-weak"
      >
        <h1 class="text-lg font-medium text-n-slate-12">
          {{ t('PIPELINE.TITLE') }}
        </h1>
        <Select
          v-if="pipelines.length"
          v-model="selectedPipeline"
          :options="pipelineOptions"
          :aria-label="t('PIPELINE.SELECT_PLACEHOLDER')"
        />
        <div v-if="isAdmin" class="flex items-center gap-2 ms-auto">
          <Button
            v-if="board"
            :label="t('PIPELINE.ACTIONS.EDIT_PIPELINE')"
            icon="i-lucide-settings-2"
            faded
            slate
            sm
            @click="pipelineFormRef.open(board)"
          />
          <Button
            v-if="board"
            :label="t('PIPELINE.ACTIONS.NEW_STAGE')"
            icon="i-lucide-plus"
            faded
            slate
            sm
            @click="stageDialogRef.open()"
          />
          <Button
            :label="t('PIPELINE.ACTIONS.NEW_PIPELINE')"
            icon="i-lucide-plus"
            sm
            @click="pipelineFormRef.open()"
          />
        </div>
      </header>

      <div v-if="isLoading" class="flex items-center justify-center flex-1">
        <Spinner />
      </div>
      <div
        v-else-if="!pipelines.length"
        class="flex flex-col items-center justify-center flex-1 gap-2 px-6 text-center"
      >
        <h2 class="text-base font-medium text-n-slate-12">
          {{ t('PIPELINE.EMPTY.TITLE') }}
        </h2>
        <p class="max-w-md text-sm text-n-slate-11">
          {{
            isAdmin
              ? t('PIPELINE.EMPTY.ADMIN_DESCRIPTION')
              : t('PIPELINE.EMPTY.AGENT_DESCRIPTION')
          }}
        </p>
      </div>
      <Draggable
        v-else-if="board"
        v-model="board.stages"
        item-key="id"
        handle=".stage-handle"
        :disabled="!isAdmin"
        class="flex flex-1 min-h-0 gap-4 p-6 overflow-x-auto"
        @end="reorderStages"
      >
        <template #item="{ element }">
          <PipelineStageColumn
            :stage="element"
            :can-manage-stages="isAdmin"
            @add-card="cardDialogRef.open({ stageId: $event.id })"
            @open-card="
              cardDialogRef.open({ card: $event, stageId: element.id })
            "
            @edit-stage="stageDialogRef.open($event)"
            @move-card="moveCard"
          />
        </template>
      </Draggable>
    </template>

    <PipelineFormDialog
      ref="pipelineFormRef"
      :is-loading="isSaving"
      @submit="savePipeline"
      @delete="deletePipeline"
    />
    <PipelineStageDialog
      ref="stageDialogRef"
      :is-loading="isSaving"
      @submit="saveStage"
      @delete="deleteStage"
    />
    <PipelineCardDialog
      ref="cardDialogRef"
      :is-loading="isSaving"
      @submit="saveCard"
      @delete="deleteCard"
    />
    <Dialog
      ref="confirmDialogRef"
      type="alert"
      :title="confirmation.title"
      :description="confirmation.description"
      :confirm-button-label="t('PIPELINE.CONFIRM_DELETE')"
      :is-loading="isSaving"
      width="sm"
      @confirm="confirm"
    />
  </section>
</template>
