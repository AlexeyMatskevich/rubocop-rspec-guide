# frozen_string_literal: true

# Inject our default configuration into RuboCop
# This ensures config/default.yml is loaded automatically
module RuboCop
  module RSpec
    module Guide
      # Inject default configuration
      module Inject
        DEFAULT_FILE = File.expand_path("../../../../../config/default.yml", __FILE__)

        def self.defaults!
          path = DEFAULT_FILE
          hash = ConfigLoader.send(:load_yaml_configuration, path)
          config = Config.new(hash, path).tap(&:make_excludes_absolute)
          puts "configuration from #{path}" if ConfigLoader.debug?
          config = ConfigLoader.merge_with_default(config, path)
          ConfigLoader.instance_variable_set(:@default_configuration, config)
        end
      end
    end
  end
end

# Inject defaults when the gem is loaded
RuboCop::RSpec::Guide::Inject.defaults!
