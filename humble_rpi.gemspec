Gem::Specification.new do |s|
  s.name = 'humble_rpi'
  s.version = '0.1.5'
  s.summary = 'Designed for a Raspberry Pi which uses GPIO LEDs, 1 motion sensor and communicates with a SimplePubSub message broker'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_runtime_dependency('rpi', '~> 0.1', '>=0.1.1')
  s.add_runtime_dependency('chronic_duration', '~> 0.10', '>=0.10.4')
  s.add_runtime_dependency('websocket-eventmachine-client', '~> 1.0', '>=1.0.1')
  s.add_runtime_dependency('sps-pub', '~> 0.3', '>=0.3.0')
  s.signing_key = '../privatekeys/humble_rpi.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/humble_rpi'
  s.required_ruby_version = '>= 2.1.2'
end

