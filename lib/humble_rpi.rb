#!/usr/bin/env ruby

# file: humble_rpi.rb

require 'rpi'
require 'chronic_duration'
require 'sps-pub'
require 'rpi_lcd16x2'
require 'websocket-eventmachine-client'


class HumbleRPi
  include PiPiper  

  attr_reader :led, :lcd

  def initialize(options={})

    default_options = {
      device_name: 'rpi',
      lcd_pins:  {},
      led_pins:  [],
      motion_pin: nil, 
      sps_address: nil, 
      sps_port: '59000'
    }

    @opt = default_options.merge options
    send_message 'humble_rpi initialized'
    led_pins, lcd_pins = @opt[:led_pins], @opt[:lcd_pins]
    
    @lcd = RpiLcd16x2.new 'ready', lcd_pins if lcd_pins.any?
    @led = RPi.new(led_pins).led            if led_pins.any?
    @ws = nil
  end

  def send_message(msg)

    topic, address, port = @opt[:device_name], @opt[:sps_address], @opt[:sps_port]
    fqm = (topic + ': ' + msg)
    address ? SPSPub.notice(fqm, address: address, port: port) : puts(fqm)
  end
  
  protected

  def listener(&blk)

    rpi = self

    c = WebSocket::EventMachine::Client

    Thread.new do   
      
      EM.run do

        @ws = c.connect(uri: "ws://%s:%s" % [@opt[:sps_address], @opt[:sps_port]])

        @ws.onopen do
          puts "Client connected"          
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

    alias led_listener listener
  end

  def motion_detect()

    send_message 'motion detection activated'
    t1 = Time.now - ChronicDuration.parse('1 minute and 10 seconds')
    topic = @opt[:device_name]
    address, port = @opt[:sps_address], @opt[:sps_port]

    hrpi = self

    after pin: @opt[:motion_pin].to_i, goes: :high do

      if Time.now > t1 + ChronicDuration.parse('1 minute')  then
        hrpi.send_message 'motion detected'
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