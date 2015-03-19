require './spec/spec_helper'

RSpec.describe DeployLocker::Locker do
  subject { described_class.new($redis, slack) }

  let(:slack) { double(:slack).tap { |o| allow(o).to receive(:notify).with(any_args) } }
  let(:env) { 'test_env' }
  let(:project) { 'sample_project' }
  let(:api_key) { 'user1' }

  before do
    stub_request(:get, 'http://https//api.github.com:80/user?access_token=user1').
      with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' }).
      to_return(status: 200, body: '{"login": "test-github-user", "id": 123456}', headers: {})

    stub_request(:get, 'http://https//api.github.com:80/user?access_token=user2').
      with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' }).
      to_return(status: 200, body: '{"login": "test-github-user2", "id": 234567}', headers: {})
  end

  describe '#lock' do
    it 'creates a key in redis with username as a value' do
      expect { subject.lock(project, env, api_key) }.to change { $redis.exists("#{project}::#{env}") }.from(false).to(true)
    end

    it 'raises error if key for project and env pair already exists' do
      subject.lock(project, env, api_key)
      expect { subject.lock(project, env, api_key) }.to raise_error(DeployLocker::Locker::AlreadyLockedError)
    end
  end

  describe '#unlock' do
    before { subject.lock(project, env, api_key) }

    it 'removes key from redis' do
      expect { subject.unlock(project, env, api_key) }.to change { $redis.exists("#{project}::#{env}") }.from(true).to(false)
    end

    it 'raises error if locking was not found by specified parameters' do
      expect { subject.unlock(project, 'other_env', api_key) }.to raise_error(DeployLocker::Locker::NoLockingExistError)
    end

    it 'raises error if locking was created by another user' do
      expect { subject.unlock(project, env, 'user2') }.to raise_error(DeployLocker::Locker::CannotBeUnlockedError)
    end
  end

  describe '#unlock_all' do
    it 'removes keys from redis by <project>::<env> pattern' do
      subject.lock(project, env, api_key)
      expect { subject.unlock_all(project, env) }.to change { $redis.keys("#{project}::#{env}").size }.from(1).to(0)
    end

    it 'removes keys for particular project if env was not specified' do
      subject.lock(project, 'env1', api_key)
      subject.lock(project, 'env2', api_key)
      expect { subject.unlock_all(project, nil) }.to change { $redis.keys("#{project}::*").size }.from(2).to(0)
    end

    it 'removes keys for particular env if project was not specified' do
      subject.lock('project1', env, api_key)
      subject.lock('project2', env, api_key)
      expect { subject.unlock_all(nil, env) }.to change { $redis.keys("*::#{env}").size }.from(2).to(0)
    end

    it 'removes keys for all projects/environments if no params specified' do
      subject.lock('project1', 'dev1', 'user1')
      subject.lock('project2', 'dev2', 'user2')
      expect { subject.unlock_all(nil, nil) }.to change { $redis.keys("*::*").size }.from(2).to(0)
    end
  end
end
