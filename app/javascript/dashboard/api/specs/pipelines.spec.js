import pipelinesAPI from '../pipelines';
import ApiClient from '../ApiClient';

describe('#PipelinesAPI', () => {
  it('creates correct instance', () => {
    expect(pipelinesAPI).toBeInstanceOf(ApiClient);
    expect(pipelinesAPI).toHaveProperty('get');
    expect(pipelinesAPI).toHaveProperty('show');
    expect(pipelinesAPI).toHaveProperty('update');
    expect(pipelinesAPI).toHaveProperty('delete');
    expect(pipelinesAPI.url).toBe('/api/v1/pipelines');
  });

  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
      patch: vi.fn(() => Promise.resolve()),
      delete: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#createPipeline sends the name and the initial stages', () => {
      pipelinesAPI.createPipeline({ name: 'Vendas', stageNames: ['Novo'] });
      expect(axiosMock.post).toHaveBeenCalledWith('/api/v1/pipelines', {
        pipeline: { name: 'Vendas' },
        stage_names: ['Novo'],
      });
    });

    it('#createItem adds a conversation to a stage', () => {
      pipelinesAPI.createItem(1, { conversationId: 42, stageId: 3 });
      expect(axiosMock.post).toHaveBeenCalledWith('/api/v1/pipelines/1/items', {
        conversation_id: 42,
        pipeline_stage_id: 3,
      });
    });

    it('#moveItem sends the target stage and position', () => {
      pipelinesAPI.moveItem(1, 9, { stageId: 4, position: 0 });
      expect(axiosMock.patch).toHaveBeenCalledWith(
        '/api/v1/pipelines/1/items/9',
        { pipeline_stage_id: 4, position: 0 }
      );
    });

    it('#updateStage sends the stage attributes', () => {
      pipelinesAPI.updateStage(1, 2, { position: 1 });
      expect(axiosMock.patch).toHaveBeenCalledWith(
        '/api/v1/pipelines/1/stages/2',
        { stage: { position: 1 } }
      );
    });

    it('#deleteStage deletes the stage', () => {
      pipelinesAPI.deleteStage(1, 2);
      expect(axiosMock.delete).toHaveBeenCalledWith(
        '/api/v1/pipelines/1/stages/2'
      );
    });
  });
});
