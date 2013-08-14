# redis-locker

A super-FAST and super-ROBUST LOCKING mechanism. Builds queue of concurrent code blocks using Redis.
If Redis fails at some point (cleared, filled with wrong data, stuck) it will be trying to stay alive anyway. This is supported by additional control-keys.

## Installing
```
$ gem install redis-locker
```

Or put in your gemfile for latest version:
```ruby
gem 'redis-locker', git: 'git://github.com/einzige/redis-locker.git'
```

## Using
```ruby
RedisLocker.new('uniq_queue_name').run!(10.minutes) do
  # Any concurrent code.
end
```

## Running specs
- Clone the repo
- run `bundle exec rake spec`

## Contributing to redis-locker

- Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
- Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
- Fork the project
- Start a feature/bugfix branch
- Commit and push until you are happy with your contribution
- Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
- Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2013 Sergei Zinin. No LICENSE for details :)
