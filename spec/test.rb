#!/usr/bin/env ruby

require 'rubygems'
require 'resque-fork'

Resque::Fork.on_action do |resource_name, from, to|
  puts "Index resource_name - #{resource_name}"
  puts "Indexing range: #{from} - #{to}"
  sleep(Random.new.rand(10))
  puts "Indexed range: #{from} - #{to}"
  puts "*****"
end

Resque::Fork.start :number_of_records => 1800000,
                   :number_of_bucket => 50000,
                   :batch_indexing_queue => "INDEX_CHANNEL",
                   :indexing_completion_channel => "INDEX_DONE",
                   :worker_count_channel => "WORKER_COUNT_CHANNEL",
                   :resource_name => "Business",
                   :realtime_queues => ["Polaris:queue:high", "Polaris:queue:low", "Polaris:queue:highlow"]