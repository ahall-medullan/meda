require 'rubygems'
require 'bundler/setup'
require 'meda'
require 'meda/collector'


use Rack::Deflater

Meda.configure do |config|
  config.disk_pool = 4
  config.google_analytics_pool = 16
  config.mapdb_path = 'db'
  config.data_path = 'meda_data'
  config.log_path = 'log/my_log.log'
  config.log_level = 1
end

dataset = Meda::Dataset.new("perf_#{Time.now.to_i}", Meda.configuration)
dataset.token = 'LOCAL_TEST'
dataset.google_analytics = {'record' => false}
Meda.datasets[dataset.token] = dataset

run Meda::Collector::App

