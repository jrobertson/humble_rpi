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
      button_pins: [],
      sps_address: nil, 
      sps_port: '59000'
    }

    @opt = default_options.merge options
    send_message :info, 'humble_rpi initialized'
    led_pins, lcd_pins = @opt[:led_pins], @opt[:lcd_pins]
    
    @lcd = RpiLcd16x2.new 'ready', lcd_pins if lcd_pins.any?
    @led = RPi.new(led_pins).led            if led_pins.any?
    @ws = nil
    
    if @opt[:motion_pin] or @opt[:button_pins] then
      
      at_exit do
        
        [@opt[:motion_pin], @opt[:button_pins]].flatten.compact.each do |pin|

          uexp = open("/sys/class/gpio/unexport", "w")
          uexp.write(pin)
          uexp.close
        
        end
      end
    end
  end

  def send_message(subtopic, msg)

    topic, address, port = @opt[:device_name], @opt[:sps_address], @opt[:sps_port]
    fqm = "%s/%s: %s" % [topic, subtopic, msg]
    
    begin
      address ? SPSPub.notice(fqm, address: address, port: port) : puts(fqm)
    rescue
      puts 'humble_rpi: warning, could not publish SPS notice.'
    end
  end
  
  protected
  
  def button_detect()

    send_message :info, 'button press detection activated'

    topic = @opt[:device_name]
    address, port = @opt[:sps_address], @opt[:sps_port]

    hrpi = self

    @opt[:button_pins].each.with_index do |button, i|
      
      puts 'button %s on GPIO %s enabled ' % [i+1, button]
      
      n = (i+1).to_s
      
      PiPiper.watch :pin => button.to_i, :invert => true do |pin|
        
        hrpi.send_message 'buttonpressed/' + n, "value %s" % [pin.value]

      end
      
    end
    
    PiPiper.wait    
    
  end  

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
          @ws.send "subscribe to topic: #{@opt[:device_name]}/output/#"
        end

        EventMachine.error_handler{ |e|
          puts "Error raised during event loop: #{e.message}"
        
        }
    
      end
     
    end

    alias led_listener listener
  end

  def motion_detect()

    send_message :info, 'motion detection activated'
    t1 = Time.now - ChronicDuration.parse('1 minute and 10 seconds')
    topic = @opt[:device_name]
    address, port = @opt[:sps_address], @opt[:sps_port]

    hrpi = self
    count  = 0

    after pin: @opt[:motion_pin].to_i, goes: :high do
      
      count += 1
      
      if Time.now > t1 + ChronicDuration.parse(duration='1 minute')  then
        hrpi.send_message :motion, "detected %s times within the past %s" \
                                                            % [count, duration]
        t1 = Time.now
        count = 0
      end

    end
    PiPiper.wait    
    
  end


end


if __FILE__ == $0 then

  # example of an RPi running with 1 LED and 1 motion sensor

  f = HumbleRPi.new device_name: 'fortina', led_pins: [17], sps_address: '192.168.4.170', motion_pin: '7'

  sleep 3 # wait for the client to connect
  f.motion_detect 

end