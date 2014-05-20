module Experian
  module PreciseId
    class Client < Experian::Client

      def initialize(logger)
        @logger = logger
      end

      def check_id(options = {})
        submit_request(PrimaryRequest.new(options))
      end

      def request_questions(options = {})
        submit_request(SecondaryRequest.new(options))
      end

      def send_answers(options = {})
        submit_request(FinalRequest.new(options))
      end

      private

      def submit_request(request)
        @logger.info "HERE IN EXPERIAN"
        @logger.info "REQUEST: #{request.inspect}"
        @logger.info "Raw response super: #{super.inspect}"
        raw_response = super
        @logger.info "EXPERIAN GEM - raw response: #{raw_response.inspect}"
        @logger.info "EXPERIAN GEM - raw response body: #{raw_response.body.inspect}"
        response = Response.new(raw_response.body)
        @logger.info "Experian Response: #{response.xml}"
        check_response(response,raw_response)
        [request,response]
      end

      def check_response(response,raw_response)
        if Experian.logger && response.error? && (response.error_code.nil? && response.error_message.nil?)
          Experian.logger.debug "Unknown Experian Error Detected, Raw response: #{raw_response.inspect}"
        end
      end

      def request_uri
        Experian.precice_id_uri
      end

    end
  end
end
