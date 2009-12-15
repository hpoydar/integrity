require "addressable/uri"
require "chronic_duration"
require "sinatra/base"
require "sinatra/url_for"
require "sinatra/authorization"
require "json"
require "haml"
require "sass"
require "dm-core"
require "dm-validations"
require "dm-types"
require "dm-timestamps"
require "dm-aggregates"

require "yaml"
require "logger"
require "digest/sha1"
require "timeout"
require "ostruct"
require "pathname"
require "forwardable"

require "integrity/core_ext/object"

require "integrity/configurator"
require "integrity/project"
require "integrity/buildable_project"
require "integrity/author"
require "integrity/commit"
require "integrity/build"
require "integrity/builder"
require "integrity/notifier"
require "integrity/notifier/base"
require "integrity/helpers"
require "integrity/app"
require "integrity/repository"
require "integrity/builder"
require "integrity/builder/threaded"

module Integrity
  class << self
    attr_accessor :builder, :directory, :base_url, :logger
  end

  def self.configure(&block)
    @config ||= Configurator.new(&block)
    @config.tap { |c| block.call(c) if block }
  end

  def self.log(message, &block)
    logger.info(message, &block)
  end

  def self.app
    unless base_url
      warn "The base_url option will be mendatory in the next release"
    end

    Integrity::App
  end
end
