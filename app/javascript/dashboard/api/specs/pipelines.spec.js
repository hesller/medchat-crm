import pipelinesAPI from '../pipelines';
import ApiClient from '../ApiClient';

describe('#PipelinesAPI', () => {
  it('creates correct instance', () => {
    expect(pipelinesAPI).toBeInstanceOf(ApiClient);
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

    it('#reorderStages sends every stage id in order', () => {
      pipelinesAPI.reorderStages(1, [3, 2]);
      expect(axiosMock.patch).toHaveBeenCalledWith(
        '/api/v1/pipelines/1/stages/reorder',
        { ids: [3, 2] }
      );
    });

    it('#createCard wraps the card', () => {
      pipelinesAPI.createCard(1, { title: 'Deal', pipeline_stage_id: 4 });
      expect(axiosMock.post).toHaveBeenCalledWith('/api/v1/pipelines/1/cards', {
        card: { title: 'Deal', pipeline_stage_id: 4 },
      });
    });

    it('#moveCard sends the target stage and position', () => {
      pipelinesAPI.moveCard(1, 9, { stageId: 4, position: 2 });
      expect(axiosMock.patch).toHaveBeenCalledWith(
        '/api/v1/pipelines/1/cards/9/move',
        { pipeline_stage_id: 4, position: 2 }
      );
    });

    it('#deleteStage targets the nested stage', () => {
      pipelinesAPI.deleteStage(1, 4);
      expect(axiosMock.delete).toHaveBeenCalledWith(
        '/api/v1/pipelines/1/stages/4'
      );
    });
  });
});
