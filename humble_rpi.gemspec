Gem::Specification.new do |s|
  s.name = 'humble_rpi'
  s.version = '0.7.0'
  s.summary = 'Controls components wired in through the Raspberry Pi\'s GPIO pins. see the Humble_rpi plugins.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/humble_rpi.rb']
  s.add_runtime_dependency('sps-pub', '~> 0.4', '>=0.4.3')
  s.add_runtime_dependency('sps-sub-ping', '~> 0.1', '>=0.1.0')
  s.signing_key = '../privatekeys/humble_rpi.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/humble_rpi'
  s.required_ruby_version = '>= 2.1.0'
end

