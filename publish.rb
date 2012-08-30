#!/bin/env ruby

require 'optparse'
require 'amqp'
require "amqp/extensions/rabbitmq"

options = {
  :host => 'localhost',
  :exchange => 'hub',
  :federated => false,
  :routing_key => `hostname -f`.chomp.split(/\./).reverse.join('.') + '.messages',
  :file_path => nil,
  :byte_count => nil, 
  :seconds => 0,
  :count => nil,
  :verbose => false,
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
  
  opts.on('-k', '--routing-key KEY', 'AMQP routing key') do |key|
    options[:routing_key] = key
  end
  
  opts.on('-f', '--file FILE', 'Publish the contents of the file in each message' ) do |file|
    options[:file_path] = file
  end

  opts.on('-b', '--bytes BYTE_COUNT', Integer, 'Publish BYTE_COUNT number of random bytes in each message' ) do |byte_count|
    options[:byte_count] = byte_count
  end
  
  opts.on('-s', '--seconds SECONDS', Float, 'Publish every N seconds') do |seconds|
     options[:seconds] = seconds
  end
  
  opts.on('-n', '--number NUMBER', Integer, 'Publish NUMBER messages and then quit') do |count|
     options[:count] = count
  end

  opts.on('-v', '--verbose', 'Show messages') do
     options[:verbose] = true
  end
  
  opts.on('--help', 'Display this screen' ) do
    puts opts
    exit
  end
 end.parse!

p options

message_content = if options[:file_path]
                    File.read(options[:file_path])
                  elsif options[:byte_count]
                    require 'securerandom'
                    SecureRandom.random_bytes(options[:byte_count])
                  else
                    ARGV.join(' ')
                  end

message_content.force_encoding 'BINARY'
    
start_time = Time.now
sent_count = 0
acked_count = 0

EventMachine.run do
  AMQP.connect(:host => options[:host]) do |connection|
    channel  = AMQP::Channel.new(connection)
    exchange = if options[:federated]
                 AMQP::Exchange.new(channel, 'x-federation', options[:exchange], :durable => true,
                                    :arguments => {"upstream-set" => "upstreams", "type" => "topic", "durable" => "true"})
               else
                 channel.topic(options[:exchange], :durable => true)
               end
                 
    # Set publisher confirms
    channel.confirm_select
    channel.on_ack do |basic_ack|
      acked_count = basic_ack.delivery_tag
      if options[:count] && acked_count >= options[:count] 
        connection.close { EM.stop }
      end
    end
    
    timer = EventMachine::PeriodicTimer.new(options[:seconds]) do
      sent_count += 1
      exchange.publish(message_content, :routing_key => options[:routing_key])
      puts "#{options[:exchange]}:#{options[:routing_key]}:#{message_content.inspect}" if options[:verbose]
      timer.cancel if options[:count] && sent_count >= options[:count]
    end

    Signal.trap("INT") { connection.close { EM.stop } }
  end
end

now = Time.now
delta_time = now - start_time
puts "Published/Acked #{sent_count}/#{acked_count} messages of #{message_content.length} bytes in #{delta_time} seconds (#{sent_count/delta_time}/#{acked_count/delta_time} msgs/sec)"
puts "#{acked_count}:#{message_content.length}:#{delta_time}"


