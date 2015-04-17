require "resque/fork/version"

require "resque"
require "resque/config"
require "resque/processor"

module Resque
  module Fork
    extend self

    def self.config
      @config ||= Resque::Fork::Config.new
    end

    def self.configure
      yield config
    end

  end
end
