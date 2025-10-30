# frozen_string_literal: true

module RuboCop
  module RSpec
    module Guide
      # Plugin integration for RuboCop 1.72+
      #
      # This class provides the modern plugin API for RuboCop.
      # It allows loading the gem via the `plugins:` configuration
      # in .rubocop.yml instead of the legacy `require:` approach.
      #
      # @example Modern approach (RuboCop 1.72+)
      #   # .rubocop.yml
      #   plugins:
      #     - rubocop-rspec-guide
      #
      # @example Legacy approach (still supported)
      #   # .rubocop.yml
      #   require:
      #     - rubocop-rspec-guide
      class Plugin
        # Initialize the plugin
        #
        # @param config [RuboCop::Config, nil] the RuboCop configuration
        def initialize(config = nil)
          @config = config
        end

        # Plugin metadata
        #
        # @return [String] the plugin name
        def name
          "rubocop-rspec-guide"
        end

        # Plugin version
        #
        # @return [String] the plugin version
        def version
          RuboCop::RSpec::Guide::VERSION
        end
      end
    end
  end
end
