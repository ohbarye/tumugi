require 'tumugi/application'
require 'tumugi/config'
require 'tumugi/logger'
require 'tumugi/version'

module Tumugi
  class << self
    def application
      @application ||= Tumugi::Application.new
    end

    def logger
      @logger ||= Tumugi::Logger.new
    end

    def config
      @config ||= Tumugi::Config.new
      yield @config if block_given?
      @config
    end
  end
end
