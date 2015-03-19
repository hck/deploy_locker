require 'sinatra'
require 'redis'
require 'yaml'
require 'slack-notify'
require 'erb'
require './lib/deploy_locker/locker'

module DeployLocker
  class App < Sinatra::Base
    config = %i(redis slack).each_with_object({}) do |name,cfg|
      erb = ERB.new File.new("config/#{name}.yml").read
      template = erb.result(binding)
      cfg[name] = YAML.load(template)[environment.to_s]
    end

    configure do
      enable :logging
      $redis = Redis.new config[:redis]
      $slack = SlackNotify::Client.new(config[:slack])
    end

    put '/lock' do
      begin
        locker.lock *params.values_at(:project, :env, :api_key)
        'ok'
      rescue Locker::AlreadyLockedError => ex
        "error: #{ex.message}"
      end
    end

    delete '/lock' do
      begin
        locker.unlock *params.values_at(:project, :env, :api_key)
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
  end
end
