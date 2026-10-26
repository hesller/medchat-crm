/* global axios */
import ApiClient from './ApiClient';

class PipelinesAPI extends ApiClient {
  constructor() {
    super('pipelines', { accountScoped: true });
  }

  createStage(pipelineId, stage) {
    return axios.post(`${this.url}/${pipelineId}/stages`, { stage });
  }

  updateStage(pipelineId, stageId, stage) {
    return axios.patch(`${this.url}/${pipelineId}/stages/${stageId}`, {
      stage,
    });
  }

  deleteStage(pipelineId, stageId) {
    return axios.delete(`${this.url}/${pipelineId}/stages/${stageId}`);
  }

  reorderStages(pipelineId, ids) {
    return axios.patch(`${this.url}/${pipelineId}/stages/reorder`, { ids });
  }

  createCard(pipelineId, card) {
    return axios.post(`${this.url}/${pipelineId}/cards`, { card });
  }

  updateCard(pipelineId, cardId, card) {
    return axios.patch(`${this.url}/${pipelineId}/cards/${cardId}`, { card });
  }

  deleteCard(pipelineId, cardId) {
    return axios.delete(`${this.url}/${pipelineId}/cards/${cardId}`);
  }

  moveCard(pipelineId, cardId, { stageId, position }) {
    return axios.patch(`${this.url}/${pipelineId}/cards/${cardId}/move`, {
      pipeline_stage_id: stageId,
      position,
    });
  }
}

export default new PipelinesAPI();
