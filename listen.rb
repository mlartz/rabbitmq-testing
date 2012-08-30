#!/bin/env ruby

require 'optparse'
require 'amqp'

options = {
  :host => 'localhost',
  :exchange => 'hub',
  :federated => false,
  :queue => "queue-#{`hostname -f`.chomp}.#{Time.now.nsec}",
  :binding => '#',
}

OptionParser.new do|opts|
   opts.banner = "Usage: publish.rb [options] [message_string]"
 
   opts.on('-h', '--host HOST', 'AMQP host') do |host|
     options[:host] = host
   end

   opts.on('-e', '--exchange EXCHANGE', 'AMQP exchange') do |exchange|
     options[:exchange] = exchange
   end

   opts.on('--federated', 'Publish to a federated exchange') do
     options[:federated] = true
   end

  opts.on('-q', '--queue QUEUE', 'AMQP queue') do |queue|
     options[:queue] = queue
   end

   opts.on('-b', '--binding BINDING', 'AMQP routing key glob binding') do |binding|
     options[:binding] = binding
   end
  
  opts.on('--help', 'Display this screen' ) do
    puts opts
    exit
  end
 end.parse!

p options

EventMachine.run do
  AMQP.connect(:host => options[:host]) do |connection|
    channel  = AMQP::Channel.new(connection)
    exchange = if options[:federated]
                 AMQP::Exchange.new(channel, 'x-federation', options[:exchange], :durable => true,
                                    :arguments => {"upstream-set" => "upstreams", "type" => "topic", "durable" => "true"})
               else
                 channel.topic(options[:exchange], :durable => true)
               end

    channel.queue(options[:queue], :auto_delete => true).bind(exchange, :routing_key => options[:binding]).subscribe do |header, payload|
      puts "#{options[:exchange]}:#{header.routing_key}:#{payload.inspect}"
    end
  end
end

