module DeployLocker
  class Locker
    def initialize(redis, slack)
      @redis = redis
      @slack = slack
    end

    def lock(project, env, api_key)
      key = key(project, env)
      if redis.exists(key)
        raise AlreadyLockedError, "already locked by #{redis.get(key)}"
      end

      username = fetch_github_user(api_key)
      redis.set(key, username)
      slack.notify(":no_entry: Lock: #{project}:#{env} by #{username}")
    end

    def unlock(project, env, api_key)
      key = key(project, env)
      key_exists = redis.exists(key)

      unless key_exists
        raise NoLockingExistError, "no locks found by params specified (project = #{project}, env = #{env})"
      end

      username = fetch_github_user(api_key)
      if redis.get(key) != username
        raise CannotBeUnlockedError, 'lock cannot be unlocked, you are not the owner'
      end

      redis.del(key)
      slack.notify(":white_check_mark: Unlock: #{project}:#{env} by #{username}")
    end

    def unlock_all(project, env)
      key_pattern = [project, env].map { |v| v || '*'  }.join('::')
      keys = redis.keys(key_pattern)
      redis.del keys unless keys.empty?
      slack.notify(":white_check_mark: Unlocked all: #{project}:#{env}")
    end

    private
    attr_reader :redis, :slack

    def key(project, env)
      [project, env].join('::')
    end

    def fetch_github_user(access_token)
      response = Net::HTTP.get_response('https://api.github.com', "/user?access_token=#{access_token}")
      raise CannotFetchGithubUser if response.code.to_i != 200
      JSON.parse(response.body)['login']
    end

    class AlreadyLockedError < StandardError; end
    class NoLockingExistError < StandardError; end
    class CannotBeUnlockedError < StandardError; end

    class CannotFetchGithubUser < StandardError; end
  end
end
