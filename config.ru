require './app'
require_all 'lib/**/*.rb'

environment = ENV["RACK_ENV"] || "development"

run CaptchaSolverApp
