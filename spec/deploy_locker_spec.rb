require './spec/spec_helper'

describe 'DeployLocker', :feature do
  let(:request_params) do
    {username: 'user', env: 'testenv', project: 'sample_project' }
  end

  describe 'PUT /lock' do
    it 'responds with ok' do
      put '/lock', request_params
      expect(last_response).to be_ok
      expect(last_response.body).to eq('ok')
    end

    it 'responds with error message when user tries to create lock which already exists' do
      put '/lock', request_params
      put '/lock', request_params.merge(username: 'user2')
      expect(last_response).to be_ok
      expect(last_response.body).to include('error: already locked')
    end
  end

  describe 'DELETE /lock' do
    before do
      put '/lock', request_params
    end

    it 'responds with ok after unlocking existing lock' do
      delete '/lock', request_params
      expect(last_response).to be_ok
      expect(last_response.body).to eq('ok')
    end

    it 'responds with error message if no locking found' do
      delete '/lock', request_params.merge(project: 'sample_project2')
      expect(last_response).to be_ok
      expect(last_response.body).to include('error: no locks found')
    end

    it 'responds with error message if locking is not found for specified user' do
      delete '/lock', request_params.merge(username: 'user2')
      expect(last_response).to be_ok
      expect(last_response.body).to include('error: lock cannot be unlocked')
    end
  end

  describe 'DELETE /unlock_all' do
    it 'responds with ok' do
      delete '/unlock_all'
      expect(last_response).to be_ok
      expect(last_response.body).to eq('ok')
    end
  end
end
