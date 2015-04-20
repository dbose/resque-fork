module Resque
  module Fork
    class Railtie < ::Rails::Railtie

      config.after_initialize do
        require 'resque'
        require File.expand_path(File.join('../worker'), File.dirname(__FILE__))
      end

    end
  end
end