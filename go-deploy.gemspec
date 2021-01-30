require File.expand_path('../lib/go_deploy/version', __FILE__)

Gem::Specification.new do |s|
  s.name      = 'go-deploy'
  s.version   = GoDeploy::VERSION
  s.platform  = Gem::Platform::RUBY
  s.summary   = 'Ruby gem for easy to deploy golang to server(ssh)'
  s.description = 'Ruby gem for easy to deploy golang to server(ssh)'
  s.authors   = ['Saharak Manoo']
  s.email     = ['saharakmanoo@gmail.com']
  s.homepage  = 'https://rubygems.org/gems/go-deploy'
  s.license   = 'MIT'
  s.files     = ['lib/go_deploy.rb', 'lib/go_deploy/console.rb', 'lib/go_deploy/deploy.rb', 'lib/go_deploy/string.rb']
  s.require_paths = ['lib']
  s.executables << 'go-deploy'

  s.required_ruby_version = '>= 2.0'
  s.add_development_dependency 'net-scp', '~> 3.0'
  s.add_development_dependency 'net-ssh', '~> 3.2'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'securerandom', '~> 0.1.0'
end
