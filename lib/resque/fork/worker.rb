require 'resque'
require 'resque-pause'

module Resque
  module Fork

    class Worker

      #
      # Configures the worker
      # @param [Resque::Fork::Config] config
      #
      def self.configure(config)
        @config = config

        Resque.after_timeout do |worker|
          on_completion(worker)
        end

        #
        # Used namespaced redis
        Resque.before_first_fork do
          on_first_fork()
        end

        Resque.before_fork do
          on_before_fork()
        end

        Resque.after_fork do
          on_after_fork()
        end
      end

      def self.on_first_fork
        Resque.redis = @config.redis
      end

      def self.on_before_fork
        Resque.logger.formatter = Resque::VerboseFormatter.new
      end

      def self.on_after_fork
        ActiveRecord::Base.verify_active_connections! if defined?(ActiveRecord::Base)
      end

      def self.queue_key
        "queue:#{@config.batch_indexing_queue}"
      end

      #
      # If resque pool is managing the workers, returns the pool process id
      #
      #  ps -A | grep [r]esque
      #
      #   5290 ??         0:11.61 resque-pool-master[omg-polaris]: managing [5293, 5294]
      #   5293 ??         0:04.64 resque-1.25.2: Waiting for low
      #   5294 ??         0:04.61 resque-1.25.2: Waiting for high
      def self.resque_pool
        `pgrep -f resque-pool`.split("\n").first
      end

      #
      # Handle the timeout case and infer job done
      # @param [Resque::Worker] worker
      #
      def self.on_completion(worker)
        puts "Process: #{Process.pid} is exiting"

        #
        # Check (in a race-free manner) whether we are the last worker to be exited.
        # In that case we need to ensure about un-pausing the real-time queue
        #
        @config.redis.watch(self.queue_key) do

          # If we are the last one
          if @config.redis.llen(self.queue_key) != 1
            @config.redis.unwatch
          else
            @config.redis.multi do
              self.on_resume_realtime_queue()
            end
          end

          # graceful shutdown
          worker.shutdown

          # kill the process
          exit 0
        end

        #@config.redis.multi do
        #  @config.redis.decr @config.worker_count_channel
        #  @config.redis.publish @config.indexing_completion_channel, {:id => worker.to_s}.to_json
        #end
        #
        #exit 0
      end

      #
      # Resume the real-time queue
      def self.on_resume_realtime_queue
        puts "Resuming RT queue"

        # Check for pool
        pool = self.resque_pool
        if pool
          puts "Pool pid - #{pool}"

          # Pool-managed workers
          begin
            Process.kill("CONT", pool.to_i)
          rescue Errno::ENOENT, Errno::ESRCH
          end

        else
          # Usual workers
          #
          # Queues are of form -
          #
          # "resque:Polaris:queue:high"
          #
          ::Resque::Fork.with_pristine_redis(@config) do
            @config.realtime_queues.each do |queue|
              ::ResquePauseHelper.unpause(queue)
            end
          end
        end

      end

      # This basically emulates the work done though usual -
      #
      # QUEUE=foo rake resque:worker
      #
      def self.start_processing(config)
        @worker = Resque::Worker.new(config.batch_indexing_queue)
        @worker.work()
      end

      def self.perform(resource_name, from, to)
        hook = ::Resque::Fork.hooks[:on_action]
        hook.call(resource_name, from, to) unless hook.nil?
      end

    end

  end
end