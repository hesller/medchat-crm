<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import Draggable from 'vuedraggable';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import PipelinesAPI from 'dashboard/api/pipelines';

import Button from 'dashboard/components-next/button/Button.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import PipelineCard from './components/PipelineCard.vue';
import NameDialog from './components/NameDialog.vue';
import AddConversationDialog from './components/AddConversationDialog.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const { isAdmin } = useAdmin();

const pipelines = ref([]);
const board = ref(null);
const isLoading = ref(true);
const isSaving = ref(false);

const pipelineDialogRef = ref(null);
const stageDialogRef = ref(null);
const addConversationDialogRef = ref(null);
const deletePipelineDialogRef = ref(null);
const deleteStageDialogRef = ref(null);

const editingPipeline = ref(false);
const editingStage = ref(null);
const targetStage = ref(null);

const activePipelineId = computed(
  () => Number(route.params.pipelineId) || null
);

const pipelineOptions = computed(() =>
  pipelines.value.map(pipeline => ({
    value: pipeline.id,
    label: pipeline.name,
  }))
);

const selectedPipelineId = computed({
  get: () => activePipelineId.value || '',
  set: id =>
    router.push({ name: 'pipeline_index', params: { pipelineId: id } }),
});

const boardConversationIds = computed(() =>
  (board.value?.stages || []).flatMap(stage =>
    stage.items.map(item => item.conversation.id)
  )
);

const runSaving = async action => {
  isSaving.value = true;
  try {
    return await action();
  } catch (error) {
    useAlert(error?.response?.data?.message || t('PIPELINE.ERRORS.SAVE'));
    return null;
  } finally {
    isSaving.value = false;
  }
};

const fetchBoard = async () => {
  if (!activePipelineId.value) {
    board.value = null;
    return;
  }
  try {
    const { data } = await PipelinesAPI.show(activePipelineId.value);
    board.value = data.payload;
  } catch {
    useAlert(t('PIPELINE.ERRORS.LOAD'));
  }
};

const fetchPipelines = async () => {
  const { data } = await PipelinesAPI.get();
  pipelines.value = data.payload;
};

const openFirstPipelineIfNone = () => {
  const exists = pipelines.value.some(p => p.id === activePipelineId.value);
  if (exists || !pipelines.value.length) return false;
  router.replace({
    name: 'pipeline_index',
    params: { pipelineId: pipelines.value[0].id },
  });
  return true;
};

onMounted(async () => {
  try {
    await fetchPipelines();
    if (!openFirstPipelineIfNone()) await fetchBoard();
  } catch {
    useAlert(t('PIPELINE.ERRORS.LOAD'));
  } finally {
    isLoading.value = false;
  }
});

watch(activePipelineId, fetchBoard);

// Pipeline

const openCreatePipeline = () => {
  editingPipeline.value = false;
  pipelineDialogRef.value.open();
};

const openRenamePipeline = () => {
  editingPipeline.value = true;
  pipelineDialogRef.value.open({ name: board.value.name });
};

const savePipeline = async ({ name }) => {
  const response = await runSaving(() =>
    editingPipeline.value
      ? PipelinesAPI.update(board.value.id, { pipeline: { name } })
      : PipelinesAPI.createPipeline({
          name,
          stageNames: ['NEW', 'IN_PROGRESS', 'WON', 'LOST'].map(key =>
            t(`PIPELINE.DEFAULT_STAGES.${key}`)
          ),
        })
  );
  if (!response) return;
  pipelineDialogRef.value.close();
  await fetchPipelines();
  if (editingPipeline.value) {
    board.value.name = name;
  } else {
    selectedPipelineId.value = response.data.payload.id;
  }
};

const deletePipeline = async () => {
  const response = await runSaving(() => PipelinesAPI.delete(board.value.id));
  if (!response) return;
  deletePipelineDialogRef.value.close();
  await fetchPipelines();
  if (!openFirstPipelineIfNone()) {
    router.replace({ name: 'pipeline_index', params: {} });
  }
};

// Stages

const openCreateStage = () => {
  editingStage.value = null;
  stageDialogRef.value.open();
};

const openEditStage = stage => {
  editingStage.value = stage;
  stageDialogRef.value.open({ name: stage.name, color: stage.color });
};

const saveStage = async ({ name, color }) => {
  const stage = editingStage.value;
  const response = await runSaving(() =>
    stage
      ? PipelinesAPI.updateStage(board.value.id, stage.id, { name, color })
      : PipelinesAPI.createStage(board.value.id, { name, color })
  );
  if (!response) return;
  stageDialogRef.value.close();
  if (stage) {
    Object.assign(stage, { name, color });
  } else {
    board.value.stages.push({ ...response.data.payload, items: [] });
  }
};

const moveStage = async (stage, offset) => {
  const stages = board.value.stages;
  const from = stages.indexOf(stage);
  const to = from + offset;
  stages.splice(to, 0, stages.splice(from, 1)[0]);
  const response = await runSaving(() =>
    PipelinesAPI.updateStage(board.value.id, stage.id, { position: to })
  );
  if (!response) await fetchBoard();
};

const openDeleteStage = stage => {
  editingStage.value = stage;
  deleteStageDialogRef.value.open();
};

const deleteStage = async () => {
  const stage = editingStage.value;
  const response = await runSaving(() =>
    PipelinesAPI.deleteStage(board.value.id, stage.id)
  );
  if (!response) return;
  deleteStageDialogRef.value.close();
  board.value.stages = board.value.stages.filter(s => s.id !== stage.id);
};

// Cards

const openAddConversation = stage => {
  targetStage.value = stage;
  addConversationDialogRef.value.open();
};

const addConversation = async conversationId => {
  const stage = targetStage.value;
  const response = await runSaving(() =>
    PipelinesAPI.createItem(board.value.id, {
      conversationId,
      stageId: stage.id,
    })
  );
  if (!response) return;
  addConversationDialogRef.value.close();
  stage.items.push(response.data.payload);
};

const onCardChange = async (stage, { added, moved }) => {
  const change = added || moved;
  if (!change) return;
  try {
    await PipelinesAPI.moveItem(board.value.id, change.element.id, {
      stageId: stage.id,
      position: change.newIndex,
    });
  } catch {
    useAlert(t('PIPELINE.ERRORS.MOVE'));
    await fetchBoard();
  }
};

const removeCard = async (stage, item) => {
  const response = await runSaving(() =>
    PipelinesAPI.deleteItem(board.value.id, item.id)
  );
  if (!response) return;
  stage.items = stage.items.filter(i => i.id !== item.id);
};

const openConversation = conversationId => {
  router.push({
    name: 'inbox_conversation',
    params: { conversation_id: conversationId },
  });
};
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <header
      class="flex flex-wrap items-center gap-3 px-6 py-4 border-b border-n-weak"
    >
      <h1 class="mb-0 text-xl font-medium text-n-slate-12">
        {{ t('PIPELINE.TITLE') }}
      </h1>
      <Select
        v-if="pipelines.length"
        v-model="selectedPipelineId"
        :options="pipelineOptions"
        :aria-label="t('PIPELINE.SELECT_PIPELINE')"
      />
      <div v-if="isAdmin" class="flex flex-wrap items-center gap-2 ms-auto">
        <template v-if="board">
          <Button
            icon="i-lucide-pencil"
            variant="ghost"
            color="slate"
            size="sm"
            :label="t('PIPELINE.ACTIONS.RENAME_PIPELINE')"
            @click="openRenamePipeline"
          />
          <Button
            icon="i-lucide-trash-2"
            variant="ghost"
            color="ruby"
            size="sm"
            :label="t('PIPELINE.ACTIONS.DELETE_PIPELINE')"
            @click="deletePipelineDialogRef.open()"
          />
          <Button
            icon="i-lucide-plus"
            variant="faded"
            color="slate"
            size="sm"
            :label="t('PIPELINE.ACTIONS.ADD_STAGE')"
            @click="openCreateStage"
          />
        </template>
        <Button
          icon="i-lucide-plus"
          size="sm"
          :label="t('PIPELINE.NEW_PIPELINE')"
          @click="openCreatePipeline"
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
      <span class="text-base font-medium text-n-slate-12">
        {{ t('PIPELINE.EMPTY.TITLE') }}
      </span>
      <p class="max-w-md mb-2 text-sm text-n-slate-11">
        {{
          isAdmin
            ? t('PIPELINE.EMPTY.ADMIN_DESCRIPTION')
            : t('PIPELINE.EMPTY.AGENT_DESCRIPTION')
        }}
      </p>
      <Button
        v-if="isAdmin"
        icon="i-lucide-plus"
        :label="t('PIPELINE.NEW_PIPELINE')"
        @click="openCreatePipeline"
      />
    </div>

    <div v-else-if="board" class="flex flex-1 gap-4 p-6 overflow-x-auto">
      <div
        v-for="(stage, index) in board.stages"
        :key="stage.id"
        class="flex flex-col flex-shrink-0 w-72 max-h-full rounded-xl bg-n-alpha-1"
      >
        <div class="flex items-center gap-2 px-3 pt-3 pb-2">
          <span
            class="flex-shrink-0 rounded-full size-2.5"
            :style="{ backgroundColor: stage.color }"
          />
          <span class="text-sm font-medium truncate text-n-slate-12">
            {{ stage.name }}
          </span>
          <span class="text-xs text-n-slate-11">{{ stage.items.length }}</span>
          <div v-if="isAdmin" class="flex items-center ms-auto">
            <Button
              icon="i-lucide-chevron-left"
              variant="ghost"
              color="slate"
              size="xs"
              :disabled="index === 0"
              :title="t('PIPELINE.ACTIONS.MOVE_STAGE_LEFT')"
              @click="moveStage(stage, -1)"
            />
            <Button
              icon="i-lucide-chevron-right"
              variant="ghost"
              color="slate"
              size="xs"
              :disabled="index === board.stages.length - 1"
              :title="t('PIPELINE.ACTIONS.MOVE_STAGE_RIGHT')"
              @click="moveStage(stage, 1)"
            />
            <Button
              icon="i-lucide-pencil"
              variant="ghost"
              color="slate"
              size="xs"
              :title="t('PIPELINE.ACTIONS.EDIT_STAGE')"
              @click="openEditStage(stage)"
            />
            <Button
              icon="i-lucide-trash-2"
              variant="ghost"
              color="slate"
              size="xs"
              :title="t('PIPELINE.ACTIONS.DELETE_STAGE')"
              @click="openDeleteStage(stage)"
            />
          </div>
        </div>
        <Draggable
          v-model="stage.items"
          item-key="id"
          tag="ul"
          group="pipeline-items"
          ghost-class="opacity-40"
          class="flex flex-col flex-1 min-h-16 gap-2 px-3 pb-2 mb-0 overflow-y-auto"
          @change="event => onCardChange(stage, event)"
        >
          <template #item="{ element }">
            <PipelineCard
              :item="element"
              @open="openConversation"
              @remove="item => removeCard(stage, item)"
            />
          </template>
          <template #footer>
            <li
              v-if="!stage.items.length"
              class="py-4 text-xs text-center list-none border border-dashed rounded-lg text-n-slate-10 border-n-weak"
            >
              {{ t('PIPELINE.STAGE_EMPTY') }}
            </li>
          </template>
        </Draggable>
        <div class="px-3 pb-3">
          <Button
            icon="i-lucide-plus"
            variant="ghost"
            color="slate"
            size="sm"
            class="w-full"
            :label="t('PIPELINE.ACTIONS.ADD_CONVERSATION')"
            @click="openAddConversation(stage)"
          />
        </div>
      </div>
    </div>

    <NameDialog
      ref="pipelineDialogRef"
      :title="
        editingPipeline
          ? t('PIPELINE.PIPELINE_DIALOG.EDIT_TITLE')
          : t('PIPELINE.PIPELINE_DIALOG.CREATE_TITLE')
      "
      :description="
        editingPipeline ? '' : t('PIPELINE.PIPELINE_DIALOG.CREATE_DESCRIPTION')
      "
      :name-label="t('PIPELINE.PIPELINE_DIALOG.NAME_LABEL')"
      :name-placeholder="t('PIPELINE.PIPELINE_DIALOG.NAME_PLACEHOLDER')"
      :confirm-label="
        editingPipeline
          ? t('PIPELINE.PIPELINE_DIALOG.SAVE')
          : t('PIPELINE.PIPELINE_DIALOG.CREATE')
      "
      :is-loading="isSaving"
      @confirm="savePipeline"
    />
    <NameDialog
      ref="stageDialogRef"
      :title="
        editingStage
          ? t('PIPELINE.STAGE_DIALOG.EDIT_TITLE')
          : t('PIPELINE.STAGE_DIALOG.CREATE_TITLE')
      "
      :name-label="t('PIPELINE.STAGE_DIALOG.NAME_LABEL')"
      :name-placeholder="t('PIPELINE.STAGE_DIALOG.NAME_PLACEHOLDER')"
      :color-label="t('PIPELINE.STAGE_DIALOG.COLOR_LABEL')"
      :confirm-label="
        editingStage
          ? t('PIPELINE.STAGE_DIALOG.SAVE')
          : t('PIPELINE.STAGE_DIALOG.CREATE')
      "
      :is-loading="isSaving"
      @confirm="saveStage"
    />
    <AddConversationDialog
      ref="addConversationDialogRef"
      :existing-conversation-ids="boardConversationIds"
      @select="addConversation"
    />
    <Dialog
      ref="deletePipelineDialogRef"
      type="alert"
      :title="
        t('PIPELINE.DELETE_PIPELINE_CONFIRM.TITLE', { name: board?.name })
      "
      :description="t('PIPELINE.DELETE_PIPELINE_CONFIRM.DESCRIPTION')"
      :confirm-button-label="t('PIPELINE.DELETE_PIPELINE_CONFIRM.CONFIRM')"
      :is-loading="isSaving"
      @confirm="deletePipeline"
    />
    <Dialog
      ref="deleteStageDialogRef"
      type="alert"
      :title="
        t('PIPELINE.DELETE_STAGE_CONFIRM.TITLE', { name: editingStage?.name })
      "
      :description="t('PIPELINE.DELETE_STAGE_CONFIRM.DESCRIPTION')"
      :confirm-button-label="t('PIPELINE.DELETE_STAGE_CONFIRM.CONFIRM')"
      :is-loading="isSaving"
      @confirm="deleteStage"
    />
  </section>
</template>
