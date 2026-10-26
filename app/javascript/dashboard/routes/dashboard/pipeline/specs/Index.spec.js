import { ref } from 'vue';
import { mount, flushPromises } from '@vue/test-utils';
import { withFullI18n } from 'test-i18n';
import PipelinesAPI from 'dashboard/api/pipelines';
import PipelineIndex from '../Index.vue';

withFullI18n();

const route = { params: { pipelineId: '1' } };
const router = { push: vi.fn(), replace: vi.fn() };
const isAdmin = ref(false);

vi.mock('vue-router', () => ({
  useRoute: () => route,
  useRouter: () => router,
}));
vi.mock('dashboard/composables/useAdmin', () => ({
  useAdmin: () => ({ isAdmin }),
}));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('dashboard/api/pipelines', () => ({
  default: {
    get: vi.fn(),
    show: vi.fn(),
    moveItem: vi.fn(),
  },
}));

const card = {
  id: 7,
  pipeline_stage_id: 10,
  position: 0,
  conversation: {
    id: 42,
    status: 'open',
    last_activity_at: 1761440000,
    inbox_name: 'WhatsApp',
    contact: { id: 1, name: 'Maria Souza', thumbnail: '' },
    assignee: null,
  },
};

const mountBoard = async () => {
  const wrapper = mount(PipelineIndex, {
    global: {
      stubs: { TeleportWithDirection: { template: '<div><slot /></div>' } },
    },
  });
  await flushPromises();
  return wrapper;
};

describe('PipelineIndex', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    isAdmin.value = false;
    PipelinesAPI.get.mockResolvedValue({
      data: { payload: [{ id: 1, name: 'Vendas' }] },
    });
    PipelinesAPI.show.mockResolvedValue({
      data: {
        payload: {
          id: 1,
          name: 'Vendas',
          stages: [
            { id: 10, name: 'Novo', color: '#1f93ff', items: [card] },
            { id: 11, name: 'Ganho', color: '#44ce4b', items: [] },
          ],
        },
      },
    });
  });

  it('renders each stage with its cards', async () => {
    const wrapper = await mountBoard();

    expect(PipelinesAPI.show).toHaveBeenCalledWith(1);
    expect(wrapper.text()).toContain('Novo');
    expect(wrapper.text()).toContain('Ganho');
    expect(wrapper.text()).toContain('Maria Souza');
    expect(wrapper.text()).toContain('#42');
  });

  it('hides the stage controls from agents', async () => {
    const wrapper = await mountBoard();

    expect(wrapper.find('header').text()).not.toContain('New stage');
    expect(wrapper.find('[title="Edit stage"]').exists()).toBe(false);
  });

  it('shows the stage controls to administrators', async () => {
    isAdmin.value = true;
    const wrapper = await mountBoard();

    expect(wrapper.find('header').text()).toContain('New stage');
    expect(wrapper.find('[title="Edit stage"]').exists()).toBe(true);
  });

  it('opens the conversation when a card is clicked', async () => {
    const wrapper = await mountBoard();

    await wrapper.find('li.cursor-grab').trigger('click');

    expect(router.push).toHaveBeenCalledWith({
      name: 'inbox_conversation',
      params: { conversation_id: 42 },
    });
  });
});
