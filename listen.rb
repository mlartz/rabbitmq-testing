#!/bin/env ruby

require 'amqp'

host = ARGV[0] || '127.0.0.1'

EventMachine.run do
  AMQP.connect(:host => host) do |connection|
    channel  = AMQP::Channel.new(connection)
    exchange = channel.topic("hub")
    
    queue_name = "#{`hostname`}-#{Time.now.nsec}"
    channel.queue(queue_name, :auto_delete => true).bind(exchange, :routing_key => '*').subscribe do |header, payload|
      puts "Payload: #{payload}"
    end
  end
end
