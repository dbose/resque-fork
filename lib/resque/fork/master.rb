require 'resque'
require 'resque-pause'
require "resque/fork/worker"
require 'pry'

module Resque
  module Fork

    # Master itself behaves as a worker. This is intended to remove any single-point-of-failure (SPOF)
    # Just one additional responsibility of the master is to distribute the jobs through a Resque
    # before transformed to a normal worker (indexing)
    class Master < Worker

      # @param [Resque::Fork::Config] config
      def self.distribute(config)

        self.configure(config)

        (1..@config.number_of_records.to_i).step(@config.number_of_bucket.to_i).each_with_index do |p, i|
          # config.redis.lpush  config.batch_indexing_queue, 
          #                     Marshal.dump([p, (i+1) * NO_OF_BUCKET])

          # Probably we need a resource.class.name (Business, Region etc.)
          Resque.enqueue_to(@config.batch_indexing_queue,
                            ::Resque::Fork::Worker,
                            @config.resource_name,
                            p,                     
                            (i+1) * @config.number_of_bucket.to_i)
        end
      end

      def self.pause_realtime_queue(config)
        config.redis.multi do
          puts "pausing RT queue..."

          # Check for pool
          pool = self.resque_pool

          if pool
            puts "Pool pid - #{pool}"

            # Pool-managed workers
            begin
              Process.kill("USR2", pool.to_i)
            rescue Errno::ENOENT, Errno::ESRCH
            end

          else
            # Usual workers
            #
            # Queues are of form -
            #
            # "resque:Polaris:queue:high"
            #
            ::Resque::Fork.with_pristine_redis(config) do
              config.realtime_queues.each do |queue|
                ::ResquePauseHelper.pause(queue)
              end
            end

          end

        end
      end

    end
  end
end