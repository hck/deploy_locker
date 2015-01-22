require 'sinatra'
require 'redis'
require 'yaml'
require 'slack-notify'
require './lib/locker'

redis_config = YAML.load_file('./config/redis.yml')

%i(development test).each do |environment|
  configure :development, :test do
    enable :logging
    $redis = Redis.new redis_config[environment.to_s]
  end
end

configure :development, :production do
  $slack = SlackNotify::Client.new(
    webhook_url: ENV['SLACK_WEBHOOK_URL'],
    channel: 'test-deploy-locker',
    user: 'alexsvirin',
    icon_emoji: ":shipit:",
    link_names: 1
  )
end

configure :production do
  require 'uri'
  uri = URI.parse ENV['REDISTOGO_URL']
  $redis = Redis.new host: uri.host, port: uri.port, password: uri.password
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
  locker.unlock_all *params.values_at(:project, :env)
  'ok'
end

private

def locker
  @locker ||= Locker.new($redis, $slack)
end
