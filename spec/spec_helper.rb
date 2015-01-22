require 'sinatra'
require 'sinatra/base'
require 'rack/test'
require './deploy_locker'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.include Rack::Test::Methods
end

def app
  Sinatra::Application.new
end
