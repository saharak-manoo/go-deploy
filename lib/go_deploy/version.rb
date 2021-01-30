# frozen_string_literal: true

# Gem Version
module GoDeploy
  VERSION_INFO = [1, 0, 3].freeze
  VERSION = VERSION_INFO.map(&:to_s).join('.').freeze

  def self.version
    VERSION
  end
end
