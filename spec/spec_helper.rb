require 'sinatra'
require 'sinatra/base'
require 'rack/test'
require './deploy_locker'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.include Rack::Test::Methods

  # flush redis before running each example
  config.before do
    $redis.flushdb
  end
end

def app
  Sinatra::Application.new
end
