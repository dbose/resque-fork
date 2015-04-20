require "resque/fork/version"

require 'redis'
require 'redis-namespace'

require 'resque'
require 'resque-pause'

require "resque/fork/config"
require "resque/fork/processor"
require "resque/fork/master"
require "resque/fork/worker"

module Resque
  module Fork
    extend self

    def self.hooks
      @hooks ||= {}
    end

    #
    # Configuration
    def self.config
      @config ||= Resque::Fork::Config.new
    end

    #
    # Configure resque-fork
    def self.configure
      yield config
    end

    #
    # Start distributed processing/indexing
    def self.start(options = {})
      processor = Resque::Fork::Processor.new(Resque::Fork::Config.new(options))
      processor.start
    end

    #
    # Underlying redis connection
    def self.redis
      config.redis
    end

    #
    # Temporarily expose non-namespaced redis
    def self.with_pristine_redis(config)
      begin
        Resque.redis = config.pristine_redis
        yield
      ensure
        Resque.redis = config.redis
      end
    end

    def self.on_action(&block)
      hooks[:on_action] = block
    end

  end
end
