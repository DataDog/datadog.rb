module Datadog
  # Custom error class for rescuing from all Datadog errors
  # @author Mike Fiedler <miketheman@gmail.com>

  class Error < StandardError
    # Returns the appropriate Datadog::Error subclass based
    # on status and response message
    #
    # @param [Hash] response HTTP response
    # @return [Datadog::Error]
    def self.from_response(response)
      if klass =  case response[:status].to_i
                  when 401      then Datadog::Unauthorized
                  when 403      then Datadog::Forbidden
                  when 404      then Datadog::NotFound
                  when 409      then Datadog::Conflict
                  when 422      then Datadog::UnprocessableEntity
                  when 400..499 then Datadog::ClientError
                  when 500      then Datadog::InternalServerError
                  when 501      then Datadog::NotImplemented
                  when 502      then Datadog::BadGateway
                  when 503      then Datadog::ServiceUnavailable
                  when 500..599 then Datadog::ServerError
                  end
        klass.new(response)
      end
    end

    def initialize(response = nil)
      @response = response
      super(build_error_message)
    end

    # Documentation URL returned by the API for some errors
    #
    # @return [String]
    def documentation_url
      data[:documentation_url] if data.is_a? Hash
    end

    # Array of validation errors
    # @return [Array<Hash>] Error info
    def errors
      if data && data.is_a?(Hash)
        data[:errors] || []
      else
        []
      end
    end

    private

    def data
      @data ||=
        if (body = @response[:body]) && !body.empty?
          if body.is_a?(String) &&
             @response[:response_headers] &&
             @response[:response_headers][:content_type] =~ /json/

            Sawyer::Agent.serializer.decode(body)
          else
            body
          end
        else
          nil
        end
    end

    def response_message
      case data
      when Hash
        data[:message]
      when String
        data
      end
    end

    def response_error
      "Error: #{data[:error]}" if data.is_a?(Hash) && data[:error]
    end

    def response_error_summary
      return nil unless data.is_a?(Hash) && !Array(data[:errors]).empty?

      summary = "\nError summary:\n"
      summary << data[:errors].map do |hash|
        hash.map { |k, v| "  #{k}: #{v}" }
      end.join("\n")

      summary
    end

    def build_error_message
      return nil if @response.nil?

      message =  "#{@response[:method].to_s.upcase} "
      message << redact_url(@response[:url].to_s) + ': '
      message << "#{@response[:status]} - "
      message << "#{response_message}" unless response_message.nil?
      message << "#{response_error}" unless response_error.nil?
      message << "#{response_error_summary}" unless response_error_summary.nil?
      message << " // See: #{documentation_url}" unless documentation_url.nil?
      message
    end

    def redact_url(url_string)
      %w(api_key application_key).each do |secret|
        url_string.gsub!(/#{secret}=\S+/, "#{secret}=(redacted)") if url_string.include? secret
      end
      url_string
    end
  end

  # Raised on errors in the 400-499 range
  class ClientError < Error; end

  # Raised when Datadog returns a 401 HTTP status code
  class Unauthorized < ClientError; end

  # Raised when Datadog returns a 403 HTTP status code
  class Forbidden < ClientError; end

  # Raised when Datadog returns a 404 HTTP status code
  class NotFound < ClientError; end

  # Raised when Datadog returns a 409 HTTP status code
  class Conflict < ClientError; end

  # Raised on errors in the 500-599 range
  class ServerError < Error; end

  # Raised when Datadog returns a 500 HTTP status code
  class InternalServerError < ServerError; end

  # Raised when Datadog returns a 501 HTTP status code
  class NotImplemented < ServerError; end

  # Raised when Datadog returns a 502 HTTP status code
  class BadGateway < ServerError; end

  # Raised when Datadog returns a 503 HTTP status code
  class ServiceUnavailable < ServerError; end

  # Raised when client fails to provide valid Content-Type
  class MissingContentType < ArgumentError; end

  # Raised when a method requires an application key
  # and api_key but none is provided
  class ApplicationCredentialsRequired < StandardError; end
end
