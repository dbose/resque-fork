require 'redis'
require 'redis-namespace'

module Resque
  module Fork

    class Config
      #
      # Number of records to process in a distributed manner
      attr_accessor :number_of_records

      #
      # Number of chunks each worker will handle
      attr_accessor :number_of_bucket

      #
      # Name of the distributed indexing queue
      attr_accessor :batch_indexing_queue

      #
      # Name of the channel where workers posts after completion of indexing
      attr_accessor :indexing_completion_channel
      #
      # Name of the worker registration channel
      attr_accessor :worker_count_channel

      #
      # redis channel (ideally should gathered from resque)
      attr_accessor :redis

      # 
      # Resource name (ActiveRecord class name or other meta-data)
      attr_accessor :resource_name

      # Un-namespaced redis
      #
      attr_accessor :pristine_redis

      #
      # Real-time queue name
      #
      # NOTE:
      #   A real-time queue is the usual indexing queue that will be suspended
      #   through the distributed indexing phase
      #
      attr_accessor :realtime_queues

      def initialize(options = {})
        options.each do |key, value|
          public_send("#{key}=", value || ENV[key.upcase])
        end

        # Redis connection from resque
        @redis = Redis::Namespace.new(:fork, :redis => Resque.redis)
        @pristine_redis = @redis.redis
      end

    end

  end

end