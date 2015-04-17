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
        elect_master
      end

      private

      def elect_master
        @redis.watch(@batch_indexing_queue) do
          if @redis.exists(@batch_indexing_queue)
            @redis.unwatch
            Resque::Fork::Worker.configure(@config)
            # slave_job()
          else
            @redis.multi do |multi|
              Resque::Fork::Master.orchestrate(@config)
            end
          end
        end
      end

    end

  end
end