import { frontendURL } from '../../../helper/URLHelper';
import { FEATURE_FLAGS } from '../../../featureFlags';
import PipelineIndex from './Index.vue';

const meta = {
  featureFlag: FEATURE_FLAGS.PIPELINE,
  permissions: ['administrator', 'agent', 'custom_role'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/pipeline/:pipelineId?'),
    component: PipelineIndex,
    name: 'pipeline_index',
    meta,
  },
];
