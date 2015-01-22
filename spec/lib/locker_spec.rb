require './spec/spec_helper'

describe Locker do
  subject { described_class.new($redis, slack) }

  let(:slack) { double(:slack).tap { |o| allow(o).to receive(:notify).with(any_args) } }
  let(:env) { 'test_env' }
  let(:project) { 'sample_project' }
  let(:username) { 'user1' }

  describe '#lock' do
    it 'creates a key in redis with username as a value' do
      expect { subject.lock(project, env, username) }.to change { $redis.exists("#{project}::#{env}") }.from(false).to(true)
    end

    it 'raises error if key for project and env pair already exists' do
      subject.lock(project, env, username)
      expect { subject.lock(project, env, username) }.to raise_error(Locker::AlreadyLockedError)
    end
  end

  describe '#unlock' do
    before { subject.lock(project, env, username) }

    it 'removes key from redis' do
      expect { subject.unlock(project, env, username) }.to change { $redis.exists("#{project}::#{env}") }.from(true).to(false)
    end

    it 'raises error if locking was not found by specified parameters' do
      expect { subject.unlock(project, 'other_env', username) }.to raise_error(Locker::NoLockingExistError)
    end

    it 'raises error if locking was created by another user' do
      expect { subject.unlock(project, env, 'user2') }.to raise_error(Locker::CannotBeUnlockedError)
    end
  end

  describe '#unlock_all' do
    it 'removes keys from redis by <project>::<env> pattern' do
      subject.lock(project, env, username)
      expect { subject.unlock_all(project, env) }.to change { $redis.keys("#{project}::#{env}").size }.from(1).to(0)
    end

    it 'removes keys for particular project if env was not specified' do
      subject.lock(project, 'env1', username)
      subject.lock(project, 'env2', username)
      expect { subject.unlock_all(project, nil) }.to change { $redis.keys("#{project}::*").size }.from(2).to(0)
    end

    it 'removes keys for particular env if project was not specified' do
      subject.lock('project1', env, username)
      subject.lock('project2', env, username)
      expect { subject.unlock_all(nil, env) }.to change { $redis.keys("*::#{env}").size }.from(2).to(0)
    end

    it 'removes keys for all projects/environments if no params specified' do
      subject.lock('project1', 'dev1', 'user1')
      subject.lock('project2', 'dev2', 'user2')
      expect { subject.unlock_all(nil, nil) }.to change { $redis.keys("*::*").size }.from(2).to(0)
    end
  end
end
