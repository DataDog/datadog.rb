require 'datadog/response/raise_error'
# require 'Datadog/response/feed_parser'
require 'datadog/version'

module Datadog
  # Default configuration options for {Client}
  module Default
    DATADOG_HOST = 'https://app.datadoghq.com'.freeze

    # Default API endpoint with {DATADOG_HOST}
    API_ENDPOINT = "#{DATADOG_HOST}/api/v1".freeze

    # Default User Agent header string from {Datadog::VERSION}
    USER_AGENT   = "Datadog Ruby Gem #{Datadog::VERSION}".freeze

    # Default media type
    MEDIA_TYPE   = 'application/json'.freeze

    # Default Faraday middleware stack
    MIDDLEWARE = Faraday::RackBuilder.new do |builder|
      builder.use Datadog::Response::RaiseError
      # builder.use Datadog::Response::FeedParser
      builder.adapter Faraday.default_adapter
      # builder.response :logger
    end

    class << self
      # Configuration options
      # @return [Hash]
      def options
        Hash[Datadog::Configurable.keys.map { |key| [key, send(key)] }]
      end

      # Default api key from ENV
      # @return [String]
      def api_key
        ENV['DATADOG_API_KEY']
      end

      # Default application key from ENV
      # @return [String]
      def application_key
        ENV['DATADOG_APP_KEY']
      end

      # Default options for Faraday::Connection
      # @return [Hash]
      def connection_options
        {
          headers: {
            accept: default_media_type,
            user_agent: user_agent
          }
        }
      end

      # Default API Host from ENV or {DATADOG_HOST}
      # @return [String]
      def datadog_host
        ENV['DATADOG_HOST'] || DATADOG_HOST
      end

      # Default API Endpoint from ENV or {API_ENDPOINT}
      # @return [String]
      def api_endpoint
        ENV['DATADOG_API_ENDPOINT'] || API_ENDPOINT
      end

      # Default media type from ENV or {MEDIA_TYPE}
      # @return [String]
      def default_media_type
        ENV['DATADOG_MEDIA_TYPE'] || MEDIA_TYPE
      end

      # Default middleware stack for Faraday::Connection from {MIDDLEWARE}
      # @return [String]
      def middleware
        MIDDLEWARE
      end

      # Default proxy server URI for Faraday connection from ENV
      # @return [String]
      # @todo Use HTTP_PROXY variable
      def proxy
        ENV['DATADOG_PROXY']
      end

      # Default User-Agent header string from ENV or {USER_AGENT}
      # @return [String]
      def user_agent
        ENV['DATADOG_USER_AGENT'] || USER_AGENT
      end
    end
  end
end
