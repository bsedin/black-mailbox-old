require './app'

run Rack::URLMap.new(
  '/' => BlackMailbox
)
