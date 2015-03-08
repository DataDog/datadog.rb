module Datadog
  # Configuration options for {Client}, defaulting to values in {Default}
  module Configurable
    # @!attribute api_endpoint
    #   @return [String] Base URL for API requests. default https://app.datadoghq.com/api/v1/
    # @!attribute [w] api_key
    #   @see http://docs.datadoghq.com/api/#auth
    #   @return [String] API Key for authentication
    # @!attribute [w] application_key
    #   @see http://docs.datadoghq.com/api/#auth
    #   @return [String] Application Key for authentication
    # @!attribute connection_options
    #   @see https://github.com/lostisland/faraday
    #   @return [Hash] Configure connection options for Faraday
    # @!attribute middleware
    #   @see https://github.com/lostisland/faraday
    #   @return [Faraday::Builder or Faraday::RackBuilder] Configure middleware for Faraday
    # @!attribute proxy
    #   @see https://github.com/lostisland/faraday
    #   @return [String] URI for proxy server

    attr_accessor :connection_options, :default_media_type, :middleware, :proxy, :user_agent
    attr_writer :api_endpoint, :api_key, :application_key

    class << self
      # List of configurable keys for {Datadog::Client}
      # @return [Array] of option keys
      def keys
        @keys ||= [
          :api_endpoint,
          :api_key,
          :application_key,
          :connection_options,
          :default_media_type,
          :middleware,
          :proxy,
          :user_agent
        ]
      end
    end

    # Set configuration options using a block
    def configure
      yield self
    end

    # Reset configuration options to default values
    def reset!
      Datadog::Configurable.keys.each do |key|
        instance_variable_set(:"@#{key}", Datadog::Default.options[key])
      end
      self
    end

    def api_endpoint
      File.join(@api_endpoint, '')
    end

    private

    def options
      Hash[Datadog::Configurable.keys.map { |key| [key, instance_variable_get(:"@#{key}")] }]
    end
  end
end
