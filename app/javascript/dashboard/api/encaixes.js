import ApiClient from './ApiClient';

class EncaixesAPI extends ApiClient {
  constructor() {
    super('encaixes', { accountScoped: true });
  }
}

export default new EncaixesAPI();
