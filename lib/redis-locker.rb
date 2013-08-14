require 'logger'
require 'redis'
require 'timeout'


class RedisLocker
  attr_reader :key, :timestamp, :timestamp_key, :time_limit, :running

  # @param [String] key
  # @param [Integer] time_limit Number of seconds when locker will be expired
  def initialize(key, time_limit = 5)
    @key = key
    @time_limit = time_limit
    @running = false
  end

  # Waits for the queue and evaluates the block
  def run(&block)
    enter_queue
    wait
    begin
      block.call
    ensure
      exit_queue
    end
  end

  # @param [Integer] time_limit Number of seconds after we throw a Timeout::Error
  # @param [true, false] clear_queue_on_timeout
  # @raise [Timeout::Error]
  def run!(time_limit = @time_limit, clear_queue_on_timeout = false, &block)
    Timeout::timeout(time_limit) { run(&block) }
  rescue Timeout::Error => error
    clear_queue if clear_queue_on_timeout
    raise error
  end

  # @return [true, false]
  def current?
    concurrent_timestamp == timestamp
  end

  # Puts running block information in Redis
  # This information will be used to place running block in a specific position of its queue
  def enter_queue
    raise 'This block is already in the queue' if running?

    @running = true
    self.timestamp = generate_timestamp.to_s

    redis.set    timestamp_key, '1'
    redis.expire timestamp_key, time_limit
    redis.rpush  key, timestamp
  end

  # Clears all data from queue related to this block
  def exit_queue
    redis.del timestamp_key
    redis.lrem key, 1, timestamp
    @running = false
  end

  # Returns true if block is ready to run
  # @return [true, false]
  def get_ready
    if ready?
      concurrent_timestamp.nil? ? start_queue : make_current
      true
    else
      current?
    end
  end

  # @param [String] concurrent_timestamp
  # @return [true, false]
  def ready?
    concurrent_timestamp.nil? || current? ||
        (generate_timestamp - concurrent_timestamp.to_f >= time_limit) ||
          redis.get(generate_timestamp_key(concurrent_timestamp)).nil?
  end

  def redis
    self.class.redis
  end

  def running?
    @running
  end

  def self.redis
    @redis
  end

  def self.redis=(adapter)
    @redis = adapter
  end

  protected

  # @return [Float]
  def generate_timestamp
    Time.now.to_f
  end

  private

  def clear_queue
    redis.del key
  end

  # @return [String]
  def concurrent_timestamp
    @concurrent_timestamp ||= fetch_concurrent_timestamp
  end

  # Fetches next concurrent thread ID from the queue
  def fetch_concurrent_timestamp
    redis.lindex(key, 0)
  end

  # @param [String, Float] timestamp
  def generate_timestamp_key(timestamp = @timestamp)
    "Locker::__key_#{timestamp}"
  end

  # Replaces concurrent timestamp
  def make_current
    redis.lrem  key, 0, timestamp
    redis.lpop  key
    redis.lpush key, timestamp
  end
  alias_method :replace_concurrent_timestamp, :make_current

  # Builds queue starting from self
  def start_queue
    redis.lpush key, timestamp
  end

  # @param [Float] value
  def timestamp=(value)
    @timestamp = value
    @timestamp_key = generate_timestamp_key(@timestamp)
    @timestamp
  end

  # Locking itself
  def wait
    begin
      @concurrent_timestamp = fetch_concurrent_timestamp
    end until get_ready
  end
end