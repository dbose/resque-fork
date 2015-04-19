require 'redis'
require 'redis-namespace'

module Resque
  module Fork

    # Main class which orchestrates the fork-join parallelism through
    # redis-resque
    #
    class Processor
      attr_accessor :resource_name

      # @param [Resque::Fork::Config] config
      # @param [String] resource name
      def initialize(config)
        @config  = config

        # Ensure Resque uses our namespaced redis connection
        Resque.redis = @config.redis        
      end

      def start
        start_internal
      end

      private

      def start_internal
        @config.redis.watch(@config.batch_indexing_queue) do
          if @config.redis.exists(@config.batch_indexing_queue)
            @config.redis.unwatch
            Resque::Fork::Worker.configure(@config)
          else
            @config.redis.multi do |multi|
              #
              # Pause the RT queue
              Resque::Fork::Master.pause_realtime_queue(@config)

              # Distribute the job
              Resque::Fork::Master.distribute(@config)
            end
          end
        end
        ::Resque::Fork::Worker.start_processing(@config)
      end

    end

  end
end