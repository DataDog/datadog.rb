source 'https://rubygems.org'

gemspec

group :doc do
  gem 'yard', require: false
end

group :localdev do
  gem 'rb-fsevent'
  gem 'guard', '~> 2.4'
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'guard-rubocop'
end

group :test do
  gem 'rspec'
  gem 'vcr'
  gem 'webmock'
end
