require 'spec_helper'

RSpec.describe 'DeployLocker::App', :feature do
  let(:request_params) do
    { api_key: 'user', env: 'testenv', project: 'sample_project' }
  end

  before do
    allow($slack).to receive(:notify).and_return(true)

    stub_request(:get, 'http://https//api.github.com:80/user?access_token=user').
      with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' }).
      to_return(status: 200, body: '{"login": "test-github-user", "id": 123456}', headers: {})

    stub_request(:get, 'http://https//api.github.com:80/user?access_token=user2').
      with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' }).
      to_return(status: 200, body: '{"login": "test-github-user2", "id": 234567}', headers: {})
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
      delete '/lock', request_params.merge(api_key: 'user2')
      expect(last_response).to be_ok
      expect(last_response.body).to include('error: lock cannot be unlocked')
    end
  end

  describe 'DELETE /unlock_all' do
    before do
      locker = DeployLocker::Locker.new($redis, $slack)
      locker.lock(*request_params.values_at(:project, :env, :api_key))
    end

    it 'responds with ok for specified project/env pair' do
      delete '/unlock_all', request_params
      expect(last_response).to be_ok
      expect(last_response.body).to eq('ok')
    end

    it 'responds with ok' do
      delete '/unlock_all'
      expect(last_response).to be_ok
      expect(last_response.body).to eq('ok')
    end
  end
end
