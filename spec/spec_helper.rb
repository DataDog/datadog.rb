require 'rspec'
require 'vcr'
require 'webmock/rspec'

# Require this library for testing
require 'datadog'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.configure_rspec_metadata!
  c.default_cassette_options = {
    record: ENV['TRAVIS'] ? :none : :once
    # record: :new_episodes, # uncomment during development
  }

  # Remove any test-specific data
  c.before_record do |i|
    i.response.headers.delete('Set-Cookie')
    i.response.headers.delete('X-Dd-Debug')
    i.response.headers.delete('X-Dd-Version')
  end
  c.filter_sensitive_data('<API_KEY>') { test_datadog_api_key }
  c.filter_sensitive_data('<APPLICATION_KEY>') { test_datadog_app_key }

  c.hook_into :webmock
end

def test_datadog_api_key
  ENV.fetch 'DATADOG_API_KEY', '9775a026f1ca7d1c6c5af9d94d9595a4'
end

def test_datadog_app_key
  ENV.fetch 'DATADOG_APP_KEY', '87614b09dd141c22800f96f11737ade5226d7ba8'
end

def stub_get(url)
  stub_request(:get, datadog_url(url))
    .with(query: {
            'api_key' => test_datadog_api_key,
            'application_key' => test_datadog_app_key
          })
end

def stub_post(url)
  stub_request(:post, datadog_url(url))
    .with(query: {
            'api_key' => test_datadog_api_key,
            'application_key' => test_datadog_app_key
          })
end

def datadog_url(url)
  return url if url =~ /^http/

  url = File.join(Datadog.api_endpoint, url)
  uri = Addressable::URI.parse(url)
  uri.path.gsub!('v1//', 'v1/')

  uri.to_s
end
