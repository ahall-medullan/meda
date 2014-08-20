require File.dirname(File.absolute_path(__FILE__)) + '/meda/version.rb'
Dir.glob(File.dirname(File.absolute_path(__FILE__)) + '/meda/core/*.rb') {|file| require file}
require "active_support/all"
require 'psych'

module Meda

  MEDA_CONFIG_FILE = 'meda.yml'
  DATASETS_CONFIG_FILE = 'datasets.yml'

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
    datasets
    logger
    true
  end

  def self.logger
    if @logger.nil? && Meda.configuration.log_path.present?
      FileUtils.mkdir_p(File.dirname(Meda.configuration.log_path))
      FileUtils.touch(Meda.configuration.log_path)
      @logger = Logger.new(Meda.configuration.log_path)
      @logger.level = Meda.configuration.log_level || Logger::INFO
    end
    @logger
  end

  def self.datasets
    if @datasets.nil?
      @datasets = {}
      begin
        config = Psych.load(File.open(Meda::DATASETS_CONFIG_FILE))
        config.each do |d_name, d_config|
          d = Meda::Dataset.new(d_name, Meda.configuration)
          d_config.each_pair { |key, val| d.send("#{key}=", val) }
          @datasets[d.token] = d
        end
      rescue Errno::ENOENT
        puts "Warning: datasets.yml missing, please create datasets manually"
      end
    end
    @datasets
  end

  class Configuration

    DEFAULTS = {
      :mapdb_path => File.join(Dir.pwd, 'db'),
      :data_path => File.join(Dir.pwd, 'data'),
      :log_path => File.join(Dir.pwd, 'log/server.log'),
      :log_level => 1,
      :disk_pool => 2,
      :google_analytics_pool => 2,
      :mail_options => {:host => 'smtp.gmail.com', :port => 587, :domain => 'medullan.com', :sender => 'ptaylor@medullan.com', :password => 'Futurtech123', 
                        :error_recipient => 'shall@medullan.com', :authentication => 'plain', :enable_tls => true}
    }

    attr_accessor :mapdb_path, :data_path, :log_path, :log_level, :disk_pool, :google_analytics_pool, :mail_options

    def initialize
      DEFAULTS.each do |key,val|
        self[key] = val
      end
    end

    def []=(key, val)
      send("#{key}=", val)
    end
  end
end

Meda.configure do |config|
  begin
    app_config = Psych.load(File.open(Meda::MEDA_CONFIG_FILE))[ENV['RACK_ENV'] || 'development']
    #puts app_config
    app_config.each_pair { |key, val| config[key] = val }
  rescue Errno::ENOENT
    puts "Warning: Missing application.yml, please configure manually"
  end
end

Meda

