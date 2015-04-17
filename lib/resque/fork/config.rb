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
      # Name of the worker registration channel
      attr_accessor :worker_count_channel

      #
      # redis channel (ideally should gathered from resque)
      attr_accessor :redis


      def initialize(options = {})
        options.each do |key, value|
          public_send("#{key}=", value || ENV[key.upcase])
        end

        # Redis connection from resque
        @redis = Redis::Namespace.new(:fork, :redis => Resque.redis)
      end

    end

  end

end