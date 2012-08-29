#!/bin/env ruby

require 'amqp'

host = ARGV[0] || '127.0.0.1'

EventMachine.run do
  AMQP.connect(:host => host) do |connection|
    channel  = AMQP::Channel.new(connection)
    exchange = channel.topic("hub")

    EventMachine.add_periodic_timer(1) do
      puts "publishing"
      exchange.publish('a'*1000000, :routing_key => 'boomtown')
    end
  end
end

