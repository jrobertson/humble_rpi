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
                                                                plugins: {})

    @device_name, @sps_address, @sps_port = device_name, sps_address, sps_port
    
    @publisher, @subscriber = if sps_address then
    
      initialize_sps() 
      
      Thread.new do  
        sp = SPSSubPing.new host: @sps_address, port: @sps_port, \
                                       identifier: 'HumbleRPi/' + device_name
        sp.start
      end
      
    else
      [DummyNotifier.new, nil]
    end      

    @plugins = initialize_plugins(plugins || [])    
    
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
      topic =  "#{@device_name}/output/#"
      @subscriber.subscribe topic: topic
    else
      loop while true
    end
    
  end

  
  private
  
  def initialize_sps()
    
    publisher = SPSPub.new address: @sps_address, port: @sps_port
    publisher.notice @device_name + '/info: humble_rpi initialized'    
    subscriber = SPSSub.new address: @sps_address, port: @sps_port, callback: self
        
    [publisher, subscriber]
    
  end
  
  def initialize_plugins(plugins)

    @plugins = plugins.inject([]) do |r, plugin|
      
      name, settings = plugin
      return r if settings[:active] == false and !settings[:active]
      
      klass_name = 'HumbleRPiPlugin' + name.to_s
                                
      vars = {device_id: @device_name, notifier: @publisher}

      r << Kernel.const_get(klass_name).new(settings: settings, variables: vars)

    end
  end  

end