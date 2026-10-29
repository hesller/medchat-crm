import { frontendURL } from '../../../helper/URLHelper';
import PipelineIndex from './Index.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/pipeline'),
    component: PipelineIndex,
    name: 'pipeline_view',
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
  },
];
