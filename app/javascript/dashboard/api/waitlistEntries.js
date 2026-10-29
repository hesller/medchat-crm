/* global axios */
import ApiClient from './ApiClient';

class WaitlistEntriesAPI extends ApiClient {
  constructor() {
    super('waitlist_entries', { accountScoped: true });
  }

  list(params = {}) {
    return axios.get(this.url, { params });
  }
}

export default new WaitlistEntriesAPI();
