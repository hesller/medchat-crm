import ApiClient from './ApiClient';

class ProfessionalsAPI extends ApiClient {
  constructor() {
    super('professionals', { accountScoped: true });
  }
}

export default new ProfessionalsAPI();
