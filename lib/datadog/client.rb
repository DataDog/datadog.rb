require 'sawyer'
require 'datadog/configurable'

module Datadog
  # Client for the Datadog API
  #
  # @see https://docs.datadoghq.com/api/
  class Client
    include Datadog::Configurable

    # Header keys that can be passed in options hash to {#get},{#head}
    CONVENIENCE_HEADERS = Set.new([:accept, :content_type])

    def initialize(options = {})
      # Use options passed in, but fall back to module defaults
      Datadog::Configurable.keys.each do |key|
        instance_variable_set(:"@#{key}", options[key] || Datadog.instance_variable_get(:"@#{key}"))
      end
    end

    # Compares client options to a Hash of requested options
    #
    # @param opts [Hash] Options to compare with current client options
    # @return [Boolean]
    def same_options?(opts)
      opts.hash == options.hash
    end

    # Text representation of the client, masking tokens and passwords
    #
    # @return [String]
    def inspect
      inspected = super

      # Only show last 4 of api_key, application_key
      if @api_key
        inspected = inspected.gsub! @api_key, "#{'*' * 28}#{@api_key[28..-1]}"
      end
      if @application_key
        inspected = inspected.gsub! @application_key, "#{'*' * 36}#{@application_key[36..-1]}"
      end

      inspected
    end

    # Make a HTTP GET request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Query and header params for request
    # @return [Sawyer::Resource]
    def get(url, options = {})
      request :get, url, parse_query_and_convenience_headers(options)
    end

    # Make a HTTP POST request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Body and header params for request
    # @return [Sawyer::Resource]
    def post(url, options = {})
      request :post, url, options
    end

    # Make a HTTP PUT request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Body and header params for request
    # @return [Sawyer::Resource]
    def put(url, options = {})
      request :put, url, options
    end

    # Make a HTTP PATCH request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Body and header params for request
    # @return [Sawyer::Resource]
    def patch(url, options = {})
      request :patch, url, options
    end

    # Make a HTTP DELETE request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Query and header params for request
    # @return [Sawyer::Resource]
    def delete(url, options = {})
      request :delete, url, options
    end

    # Make a HTTP HEAD request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Query and header params for request
    # @return [Sawyer::Resource]
    def head(url, options = {})
      request :head, url, options
    end

    # Hypermedia agent for the Datadog API
    #
    # @return [Sawyer::Agent]
    def agent
      @agent ||= Sawyer::Agent.new(api_endpoint, sawyer_options) do |http|
        http.headers[:accept] = default_media_type
        http.headers[:content_type] = 'application/json'
        http.headers[:user_agent] = user_agent

        # @todo move this to a merge for auth
        # @see https://github.com/octokit/octokit.rb/blob/master/lib/octokit/client.rb#L230
        http.params[:api_key] = @api_key
        http.params[:application_key] = @application_key if @application_key
      end
    end

    # Validate an API Key
    #
    # @return [Sawyer::Resource]
    def validate
      get 'validate'
    end

    # Response for last HTTP request
    #
    # @return [Sawyer::Response]
    def last_response
      @last_response if defined? @last_response
    end

    # Duplicate client using api_key and client_secret as
    # Basic Authentication credentials.
    # @example
    #   Datadog.api_key = "foo"
    #   Datadog.client_secret = "bar"
    #
    #   # GET https://app.datadoghq.com/?api_key=foo&client_secret=bar
    #   Datadog.get "/"
    #
    #   Datadog.client.as_app do |client|
    #     # GET https://foo:bar@api.github.com/
    #     client.get "/"
    #   end
    # @todo Determine if this is still needed
    # def as_app(key = api_key, secret = client_secret, &_block)
    #   if key.to_s.empty? || secret.to_s.empty?
    #     fail ApplicationCredentialsRequired, 'api_key and client_secret required'
    #   end
    #   app_client = dup
    #   app_client.api_key  = app_client.client_secret = nil
    #   app_client.login    = key
    #   app_client.password = secret
    #
    #   yield app_client if block_given?
    # end

    # Set Datadog API Key
    #
    # @param value [String] 32 character Datadog API Key
    def api_key=(value)
      reset_agent
      @api_key = value
    end

    # Set Datadog API Application Key
    #
    # @param value [String] 40 character Datadog API Application Key
    def appplication_key=(value)
      reset_agent
      @application_key = value
    end

    private

    def reset_agent
      @agent = nil
    end

    def request(method, path, data, options = {})
      if data.is_a?(Hash)
        options[:query]   = data.delete(:query) || {}
        options[:headers] = data.delete(:headers) || {}
        # if accept = data.delete(:accept)
        #    options[:headers][:accept] = accept
        # end
        # options[:headers][:accept] = accept if accept == data.delete(:accept)
      end

      @last_response = response = agent.call(method, URI::Parser.new.escape(path.to_s), data, options)
      response.data
    end

    # Executes the request, checking if it was successful
    #
    # @return [Boolean] True on success, false otherwise
    def boolean_from_response(method, path, options = {})
      request(method, path, options)
      @last_response.status == 204
    rescue Datadog::NotFound
      false
    end

    def sawyer_options
      opts = {
        links_parser: Sawyer::LinkParsers::Simple.new
      }
      conn_opts = @connection_options
      conn_opts[:builder] = @middleware if @middleware
      conn_opts[:proxy] = @proxy if @proxy
      opts[:faraday] = Faraday.new(conn_opts)

      opts
    end

    def parse_query_and_convenience_headers(options)
      headers = options.fetch(:headers, {})
      CONVENIENCE_HEADERS.each do |h|
        if header = options.delete(h)
          headers[h] = header
        end
      end
      query = options.delete(:query)
      opts = { query: options }
      opts[:query].merge!(query) if query && query.is_a?(Hash)
      opts[:headers] = headers unless headers.empty?

      opts
    end
  end
end
