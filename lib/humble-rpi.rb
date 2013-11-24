#!/usr/bin/env ruby

# file: humble_rpi.rb

require 'rpi'
require 'chronic_duration'
require 'websocket-eventmachine-client'


class HumbleRPi < RPi
  include PiPiper  

  def initialize(options={})

    default_options = {
      device_name: 'rpi',
      led_pins: [],
      motion_pin: nil, 
      sps_address: nil, 
      sps_port: '59000'
    }

    @opt = default_options.merge options
    super @opt[:led_pins]
    @ws, @rpi = nil, nil
  end
  
  def led_listener(&blk)
    @rpi = self
    rpi = @rpi

    c = WebSocket::EventMachine::Client

    Thread.new do   

      EM.run do

        @ws = c.connect(uri: "ws://%s:%s" % [@opt[:sps_address], @opt[:sps_port]])

        ws.onopen do
          puts "Client connected"          
          #@ws = ws
        end

        @ws.onmessage(&blk)

        @ws.onclose do
          puts "Client disconnected"
        end

        EventMachine.next_tick do
          @ws.send "subscribe to topic: #{@opt[:device_name]}_led"
        end
        EventMachine.error_handler{ |e|
          puts "Error raised during event loop: #{e.message}"
        
        }
    
      end
     
    end

  end

  def motion_detect()

    t1 = Time.now
    ws, opt = @ws, @opt

    after pin: opt[:motion_pin].to_i, goes: :high do

      #puts Time.now.to_s + ' : motion detected'

      if Time.now > t1 + ChronicDuration.parse('1 minute')  then
        ws.send opt[:device_name] + ': motion detected'
        t1 = Time.now
      end

    end
    PiPiper.wait    
    
  end
end


if __FILE__ == $0 then

  # example of an RPi running with 1 LED and 1 motion sensor

  f = HumbleRPi.new device_name: 'fortina', led_pins: [17], sps_address: '192.168.4.170', motion_pin: '7'
  rpi = f

  onmessage = lambda do |msg,type|

    puts 'message received'

    topic, raw_message = msg.split(/\s*:\s*/,2)
    r = raw_message.match(/(\d+)\s*(on|off|blink)\s*([\d\.]+)?/)

    if r then
      index, state, seconds = r.captures
    elsif raw_message[/mpd|audio/] then
      
      h = {'mpd play' => :on, 'mpd stop' => :off, 
           'audio on' => :on, 'audio off' => :off}
      index, state = 0, h[raw_message]
      
    end

    # seconds should be nil unless state == blink
    if seconds then            
      rpi.led[index.to_i].blink seconds.to_f
    else
      rpi.led[index.to_i].send(state.to_sym)
    end

  end

  f.led_listener &onmessage
  sleep 3 # wait for the client to connect
  f.motion_detect 

end
