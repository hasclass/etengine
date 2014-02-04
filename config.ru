# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

if defined?(Unicorn::HttpRequest)
  require 'gctools/oobgc'
  use GC::OOB::UnicornMiddleware
end

use Rack::Cors do
  allow do
    origins '*'
    resource '/api/*', :headers => :any, :methods => [:get, :post, :put, :delete]
  end
end

run Etm::Application
