require 'sinatra'
require 'redis'
require 'yaml'
require './lib/locker'

%i(development production test).each do |environment|
  config = YAML.load_file('./redis.yml')

  configure environment do
    $redis = Redis.new config[environment.to_s]
  end
end

put '/lock' do
  begin
    locker.lock *params.values_at(:project, :env, :username)
    'ok'
  rescue Locker::AlreadyLockedError => ex
    "error: #{ex.message}"
  end
end

delete '/lock' do
  begin
    locker.unlock *params.values_at(:project, :env, :username)
    'ok'
  rescue Locker::NoLockingExistError, Locker::CannotBeUnlockedError => ex
    "error: #{ex.message}"
  end
end

delete '/unlock_all' do
  locker.unlock_all *params.values_at(:project, :env, :username)
  'ok'
end

private

def locker
  @locker ||= Locker.new($redis)
end
