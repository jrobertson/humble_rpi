Gem::Specification.new do |s|
  s.name = 'humble_rpi'
  s.version = '0.1.0'
  s.summary = 'Designed for a Raspberry Pi which uses GPIO LEDs, 1 motion sensor and communicates with a SimplePubSub message broker'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_dependency('rpi')
  s.signing_key = '../privatekeys/humble_rpi.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/humble_rpi'
end
