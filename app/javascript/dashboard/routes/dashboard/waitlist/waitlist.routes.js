import { frontendURL } from '../../../helper/URLHelper';
import WaitlistIndex from './Index.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/waitlist'),
    component: WaitlistIndex,
    name: 'waitlist_view',
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
  },
];
