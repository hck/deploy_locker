require './spec/spec_helper'

describe 'DeployLocker', :feature do
  describe 'PUT /lock' do
    it 'creates a locking' do
      put '/lock', username: 'user', env: 'test', project: 'projectname'
      expect(last_response).to be_ok
      expect(last_response.body).to eq('OK')
    end

    it 'returns error message when user tries to create lock which already exists' do
      put '/lock', username: 'user', env: 'test', project: 'projectname'
      put '/lock', username: 'user2', env: 'test', project: 'projectname'
      expect(last_response).to be_ok
      expect(last_response.body).to include('error: already locked')
    end
  end

  describe 'DELETE /lock' do
    pending
  end

  describe 'DELETE /unlock_all' do
    pending
  end
end
