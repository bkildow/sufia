require "sufia/version"
require 'blacklight'
require 'blacklight_advanced_search'
require 'hydra/head'
require 'hydra-batch-edit'
require 'resque/server'

require 'mailboxer'
require 'acts_as_follower'
require 'paperclip'
require 'nest'
require 'RMagick'
require 'activerecord-import'
require 'rails_autolink'

autoload :Zip, 'zipruby'
module Sufia
  extend ActiveSupport::Autoload

  autoload :Resque, 'sufia/queue/resque'

  attr_accessor :queue

  class Engine < ::Rails::Engine
    engine_name 'sufia'

    # Set some configuration defaults
    config.queue = Sufia::Resque::Queue
    config.enable_ffmpeg = false
    config.ffmpeg_path = 'ffmpeg'
    config.fits_message_length = 5
    config.temp_file_base = nil

    config.autoload_paths += %W(
      #{config.root}/lib/sufia/jobs
      #{config.root}/app/controllers/concerns
      #{config.root}/app/models/concerns
    )
    
    initializer "Patch active_fedora" do
      require 'sufia/active_fedora/redis'
    end

    initializer "Patch active_record" do
      require 'sufia/active_record/redis'
    end

  end

  def self.config(&block)
    @@config ||= Sufia::Engine::Configuration.new

    yield @@config if block

    return @@config
  end

  def self.queue
    @queue ||= config.queue.new('sufia')
  end

  autoload :GenericFile
  autoload :Controller
  autoload :Utils
  autoload :User
  autoload :ModelMethods
  autoload :Noid
  autoload :IdService
  autoload :HttpHeaderAuth
  autoload :SolrDocumentBehavior
  autoload :FilesControllerBehavior
  autoload :BatchEditsControllerBehavior
  autoload :DownloadsControllerBehavior
  autoload :FileContent
end

