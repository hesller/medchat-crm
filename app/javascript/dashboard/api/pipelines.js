/* global axios */
import ApiClient from './ApiClient';

class PipelinesAPI extends ApiClient {
  constructor() {
    super('pipelines', { accountScoped: true });
  }

  createPipeline({ name, stageNames }) {
    return axios.post(this.url, {
      pipeline: { name },
      stage_names: stageNames,
    });
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

  createItem(pipelineId, { conversationId, stageId }) {
    return axios.post(`${this.url}/${pipelineId}/items`, {
      conversation_id: conversationId,
      pipeline_stage_id: stageId,
    });
  }

  moveItem(pipelineId, itemId, { stageId, position }) {
    return axios.patch(`${this.url}/${pipelineId}/items/${itemId}`, {
      pipeline_stage_id: stageId,
      position,
    });
  }

  deleteItem(pipelineId, itemId) {
    return axios.delete(`${this.url}/${pipelineId}/items/${itemId}`);
  }
}

export default new PipelinesAPI();
