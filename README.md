# Introducing the Humble RPi gem

## Example

    require 'humble_rpi'

    f = HumbleRPi.new device_name: 'fortina', led_pins: [17], sps_address: '192.168.4.170', motion_pin: '7'
    rpi = f
    blk = lambda do |msg,type|

      puts 'message received'
      #@logger.debug "#{topic}: #{raw_message}"

      topic, raw_message = msg.split(/\s*:\s*/,2)
      r = raw_message.match(/(\d+)\s*(on|off|blink)\s*([\d\.]+)?/)
      puts 'r : ' + r.inspect

      if r then
        index, state, seconds = r.captures
      elsif raw_message[/mpd|audio/] then
        
        h = {'mpd play' => :on, 'mpd stop' => :off, 
             'audio on' => :on, 'audio off' => :off}
        index, state = 0, h[raw_message]
        
      end
      #=begin                    
      # seconds should be nil unless state == blink
      if seconds then            
        rpi.led[index.to_i].blink seconds.to_f
      else
        rpi.led[index.to_i].send(state.to_sym)
      end
      #=end          

    end

    f.led_listener &blk
    sleep 3 # wait for the client to connect to the SimplePubSub message broker
    f.motion_detect

Messages are sent every minute from the Raspberry Pi (Rpi) if motion is detected. Indicator LEDs are changed on the RPi if a message is received matching the subscribed topic (e.g. fortina_led). If a message received by the RPi contains the keyword 'audio' or 'mpd play' it will set the 1st LED to on.

## Resources

* [jrobertson/humble_rpi](https://github.com/jrobertson/humble_rpi)

humblerpi gem motion simplepubsub messaging
