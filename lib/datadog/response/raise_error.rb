require 'faraday'
require 'datadog/error'

module Datadog
  # Faraday response middleware
  module Response
    # This class raises an Datadog-flavored exception based
    # HTTP status codes returned by the API
    class RaiseError < Faraday::Response::Middleware
      private

      def on_complete(response)
        if (error = Datadog::Error.from_response(response)) # rubocop:disable Style/GuardClause
          fail error
        end
      end
    end
  end
end
