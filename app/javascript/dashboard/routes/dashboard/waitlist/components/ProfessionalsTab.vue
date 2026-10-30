<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import ProfessionalsAPI from 'dashboard/api/professionals';

import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ProfessionalDialog from './ProfessionalDialog.vue';
import EncaixeDialog from './EncaixeDialog.vue';

const { t } = useI18n();
const { isAdmin } = useAdmin();

const professionals = ref([]);
const isLoading = ref(false);
const dialogRef = ref(null);
const encaixeDialogRef = ref(null);

const load = async () => {
  isLoading.value = true;
  try {
    const { data } = await ProfessionalsAPI.get();
    professionals.value = data.payload;
  } catch {
    useAlert(t('WAITLIST.MESSAGES.LOAD_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const remove = async professional => {
  try {
    await ProfessionalsAPI.delete(professional.id);
    professionals.value = professionals.value.filter(
      item => item.id !== professional.id
    );
  } catch {
    useAlert(t('WAITLIST.MESSAGES.DELETE_ERROR'));
  }
};

onMounted(load);
</script>

<template>
  <div class="flex flex-col gap-4">
    <div v-if="isAdmin" class="flex justify-end">
      <Button
        :label="t('WAITLIST.PROFESSIONALS.ADD')"
        icon="i-lucide-plus"
        sm
        @click="dialogRef.open()"
      />
    </div>

    <div v-if="isLoading" class="flex items-center justify-center py-12">
      <Spinner />
    </div>
    <p
      v-else-if="!professionals.length"
      class="py-12 text-sm text-center text-n-slate-11"
    >
      {{ t('WAITLIST.PROFESSIONALS.EMPTY') }}
    </p>
    <ul v-else class="flex flex-col divide-y divide-n-weak">
      <li
        v-for="professional in professionals"
        :key="professional.id"
        class="flex items-center gap-3 py-3"
      >
        <div class="flex flex-col gap-0.5">
          <span class="text-sm font-medium text-n-slate-12">
            {{ professional.name }}
          </span>
          <span class="text-sm text-n-slate-11">
            {{ professional.specialty }}
            <template v-if="!professional.active">
              · {{ t('WAITLIST.PROFESSIONALS.INACTIVE') }}
            </template>
          </span>
        </div>
        <div class="flex items-center gap-1 ms-auto">
          <Button
            v-if="
              professional.encaixe_daily_limit &&
              professional.encaixe_calendar_id
            "
            :label="t('WAITLIST.PROFESSIONALS.BOOK_ENCAIXE')"
            icon="i-lucide-calendar-plus"
            slate
            sm
            @click="encaixeDialogRef.open(professional)"
          />
        </div>
        <div v-if="isAdmin" class="flex items-center gap-1">
          <Button
            icon="i-lucide-pencil"
            :aria-label="t('WAITLIST.PROFESSIONALS.EDIT')"
            ghost
            slate
            sm
            @click="dialogRef.open(professional)"
          />
          <Button
            icon="i-lucide-trash-2"
            :aria-label="t('WAITLIST.PROFESSIONALS.DELETE')"
            ghost
            ruby
            sm
            @click="remove(professional)"
          />
        </div>
      </li>
    </ul>

    <ProfessionalDialog ref="dialogRef" @saved="load" />
    <EncaixeDialog ref="encaixeDialogRef" />
  </div>
</template>
