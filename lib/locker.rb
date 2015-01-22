class Locker
  def initialize(redis)
    @redis = redis
  end

  def lock(project, env, username)
    key = key(project, env)
    if redis.exists(key)
      raise AlreadyLockedError, "already locked by #{redis.get(key)}"
    end

    redis.set(key, username)
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
  end

  def unlock_all(project, env)
    p project
    p env
    key_pattern = [project, env].map { |v| v || '*'  }.join('::')
    redis.del key_pattern
  end

  private
  def redis
    @redis
  end

  def key(project, env)
    [project, env].join('::')
  end

  class AlreadyLockedError < StandardError; end
  class NoLockingExistError < StandardError; end
  class CannotBeUnlockedError < StandardError; end
end
