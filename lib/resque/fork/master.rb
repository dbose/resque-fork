

module Resque
  module Fork
    class Master

      # @param [Resque::Fork::Config] config
      def self.orchestrate(config)

        (1..config.number_of_records).step(config.number_of_bucket).each_with_index do |p, i|
          # $redis.lpush INDEX_CHANNEL, Marshal.dump([p, (i+1) * NO_OF_BUCKET])
        end
      end

    end
  end
end