require "rspec"
require "redis-locker"
require "yaml"

RSpec.configure { |config| config.mock_with :rspec }

redis = Redis.new(YAML.load_file("spec/config/redis.yml"))
RedisLocker.redis = redis

RSpec.configure do |config|
  config.filter_run_excluding integrational: true

  config.before { redis.flushdb }
  config.after { redis.flushdb }
end