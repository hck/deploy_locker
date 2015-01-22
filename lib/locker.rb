class Locker
  def initialize(redis, slack)
    @redis = redis
    @slack = slack
  end

  def lock(project, env, username)
    key = key(project, env)
    if redis.exists(key)
      raise AlreadyLockedError, "already locked by #{redis.get(key)}"
    end

    redis.set(key, username)
    slack.notify(":no_entry: Lock: #{project}:#{env} by #{username}")
  end

  def unlock(project, env, username)
    key = key(project, env)
    key_exists = redis.exists(key)

    unless key_exists
      raise NoLockingExistError, "no locks found by params specified (project = #{project}, env = #{env})"
    end

    if redis.get(key) != username
      raise CannotBeUnlockedError, 'lock cannot be unlocked, try as owner of the locking'
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

  class AlreadyLockedError < StandardError; end
  class NoLockingExistError < StandardError; end
  class CannotBeUnlockedError < StandardError; end
end
