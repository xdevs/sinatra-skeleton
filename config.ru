require File.expand_path('../application', __FILE__)

use Rack::ShowExceptions
use Rack::CommonLogger


app = Rack::Builder.new do

  use Rack::CommonLogger

  #map all the other requests to sinatra
  map '/' do
    run SinatraApp
  end
end.to_app

run app