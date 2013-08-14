#!/usr/bin/env rake

ENV['BUNDLE_GEMFILE'] = 'Gemfile'
gem_root = File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'bundler'
require 'rake'
require 'rake/testtask'
require 'rspec'
require 'rspec/core/rake_task'

task default: :spec

desc "Run the test suite"
task spec: ['spec:setup', 'spec:lib']

namespace :spec do
  desc "Setup the test environment"
  task :setup do
    system "cd #{gem_root} && bundle install && mkdir db"
  end

  desc "Test the RedisLocker lib"
  RSpec::Core::RakeTask.new(:lib) do |task|
    task.pattern = File.join(gem_root, '/spec/lib/**/*_spec.rb')
  end
end