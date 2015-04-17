require 'redis'
require 'redis-namespace'

module Resque
  module Fork

    # Main class which orchestrates the fork-join parallelism through
    # redis-resque
    #
    class Processor

      # @param [Resque::Fork::Config] config
      def initialize(config)
        @config  = config
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
            # slave_job()
          else
            @config.redis.multi do |multi|
              Resque::Fork::Master.orchestrate(@config)
            end
          end
        end
      end

    end

  end
end