<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAdmin } from 'dashboard/composables/useAdmin';

import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import WaitlistQueue from './components/WaitlistQueue.vue';
import ProfessionalsTab from './components/ProfessionalsTab.vue';
import WaitlistSettings from './components/WaitlistSettings.vue';
import { WAITLIST_TABS } from './helpers';

const { t } = useI18n();
const { isAdmin } = useAdmin();

const visibleTabs = computed(() =>
  WAITLIST_TABS.filter(tab => tab !== 'SETTINGS' || isAdmin.value)
);
const tabs = computed(() =>
  visibleTabs.value.map(tab => ({ key: tab, label: t(`WAITLIST.TABS.${tab}`) }))
);

const activeIndex = ref(0);
const activeTab = computed(() => visibleTabs.value[activeIndex.value]);

const changeTab = tab => {
  activeIndex.value = visibleTabs.value.indexOf(tab.key);
};
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <header
      class="flex flex-wrap items-center gap-4 px-6 py-4 border-b border-n-weak"
    >
      <h1 class="text-lg font-medium text-n-slate-12">
        {{ t('WAITLIST.TITLE') }}
      </h1>
      <TabBar
        :tabs="tabs"
        :initial-active-tab="activeIndex"
        @tab-changed="changeTab"
      />
    </header>
    <div class="flex-1 min-h-0 p-6 overflow-y-auto">
      <WaitlistQueue v-if="activeTab === 'QUEUE'" />
      <ProfessionalsTab v-else-if="activeTab === 'PROFESSIONALS'" />
      <WaitlistSettings v-else-if="activeTab === 'SETTINGS'" />
    </div>
  </section>
</template>
