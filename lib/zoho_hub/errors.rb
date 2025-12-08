# frozen_string_literal: true

module ZohoHub
  class Error < StandardError; end

  class RecordNotFoundError < Error; end

  class RecordInvalid < Error; end

  class InvalidTokenError < Error; end

  class InternalError < Error; end

  class InvalidRequestError < Error; end

  class InvalidQueryError < Error; end

  class InvalidModuleError < Error; end

  class NoPermissionError < Error; end

  class AuthenticationFailureError < Error; end

  class MandatoryNotFoundError < Error; end

  class RecordInBlueprintError < Error; end

  class TooManyRequestsError < Error; end

  class RecordNotInProcessError < Error; end

  class OauthScopeMismatchError < Error; end

  class ZohoAPIError < Error; end

  class ResponseFormatError < Error; end

  class BlueprintTransitionNotFound < Error
    attr_reader :new_status

    def initialize(new_status)
      @new_status = new_status
      @message = "Could not find Blueprint transition to status #{new_status}"
      super()
    end
  end
end
