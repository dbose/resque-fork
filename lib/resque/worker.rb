#
# Extended to track timeout events in a worker loop

require 'resque'

::Resque::Worker.class_eval do
  def work(interval = 5.0, &block)
    interval = Float(interval)
    $0 = "resque: Starting"
    startup

    loop do
      break if shutdown?

      if not paused? and job = reserve
        log "got: #{job.inspect}"
        job.worker = self
        working_on job

        procline "Processing #{job.queue} since #{Time.now.to_i} [#{job.payload_class_name}]"
        if @child = fork(job)
          srand # Reseeding
          procline "Forked #{@child} at #{Time.now.to_i}"
          begin
            Process.waitpid(@child)
          rescue SystemCallError
            nil
          end
          job.fail(DirtyExit.new($?.to_s)) if $?.signaled?
        else
          unregister_signal_handlers if will_fork? && term_child
          begin

            reconnect
            perform(job, &block)

          rescue Exception => exception
            report_failed_job(job,exception)
          end

          if will_fork?
            run_at_exit_hooks ? exit : exit!
          end
        end

        done_working
        @child = nil
      else
        break if interval.zero?
        log! "Sleeping for #{interval} seconds"
        procline paused? ? "Paused" : "Waiting for #{@queues.join(',')}"
        sleep interval
        run_hook :after_timeout, self
      end
    end

    unregister_worker
  rescue Exception => exception
    unless exception.class == SystemExit && !@child && run_at_exit_hooks
      log "Failed to start worker : #{exception.inspect}"

      unregister_worker(exception)
    end
  end
end

::Resque.class_eval do
  # The `after_timeout` hook will be run in the **parent** process
  # only once, if its times out while waiting for a job. Be careful- any
  # changes you make will be permanent for the lifespan of the
  # worker.
  #
  # Call with a block to register a hook.
  # Call with no arguments to return all registered hooks.
  # @overload method()
  #   Return the existing method hooks
  #   @return (see #hooks)
  # @overload method(&block)
  #   @return (see #register_hook)
  def after_timeout(&block)
    block ? register_hook(:after_timeout, block) : hooks(:after_timeout)
  end

  # Register a after_timeout proc.
  # @param block (see #register_hook)
  # @return (see #register_hook)
  def after_timeout=(block)
    register_hook(:after_timeout, block)
  end
end