#!/usr/bin/env ruby

# file: humble_rpi.rb

require 'sps-pub'
#require 'sps-sub'
require 'sps-sub-ping'


class DummyNotifier
  
  def notice(message)
    puts Time.now.to_s + ' - ' + message
  end
  
end

class HumbleRPi

  def initialize(device_name: 'rpi', sps_address: nil, sps_port: 59000, \
                                              plugins: {}, group_id: 'root')

    @device_name, @sps_address, @sps_port = device_name, sps_address, sps_port
    @group_id = group_id
    
    @publisher, @subscriber = sps_address ?  initialize_sps() \
                                                :  [DummyNotifier.new, nil]    

    @plugins = initialize_plugins(plugins || [])    
    
    at_exit do
      
      @plugins.each do |x|
        if x.respond_to? :on_exit then
          puts 'stopping ' + x.inspect
          Thread.new { x.on_exit() }
        end
      end
      
    end

  end

  # triggered from a sps-sub callback
  #
  def ontopic(topic, msg)

    component = topic[/\w+$/]

    method_name = "on_#{component}_message".to_sym

    @plugins.each do |x|

      if x.respond_to? method_name then
        x.method(method_name).call(msg)
      end

    end
  end

  def start()

    @plugins.each do |x|
      if x.respond_to? :on_start then
        puts 'starting ' + x.inspect
        Thread.new { x.on_start() }
      end
    end
        
    if @subscriber then
            
      Thread.new do
        sp = SPSSubPing.new host: @sps_address, port: @sps_port, \
                   identifier: "HumbleRPi/%s/%s" % [@group_id, @device_name]
        sp.start
      end      

      subtopics = %w(output do)
      topics = subtopics\
          .map {|x| "HumbleRPi/%s/%s/%s/#" % [@group_id, @device_name, x]}\
                                                                   .join(' | ')
      @subscriber.subscribe topic: topics
      
    else
      loop while true
    end
    
  end


  private

  def initialize_sps()

    publisher = SPSPub.new address: @sps_address, port: @sps_port
    publisher.notice  "HumbleRPi/%s/%s/info: initialized" \
                                              % [@group_id, @device_name]
    subscriber = SPSSub.new address: @sps_address, port: @sps_port,\
                                                               callback: self
    [publisher, subscriber]
    
  end
  
  def initialize_plugins(plugins)

    @plugins = plugins.inject([]) do |r, plugin|
      
      name, settings = plugin
      return r if settings[:active] == false and !settings[:active]
      
      klass_name = 'HumbleRPiPlugin' + name.to_s

      device_id = "HumbleRPi/%s/%s" % [@group_id, @device_name]
      vars = {device_id: device_id, notifier: @publisher}

      r << Kernel.const_get(klass_name)\
                                    .new(settings: settings, variables: vars)

    end
  end  

end