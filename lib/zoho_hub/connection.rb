# frozen_string_literal: true

require 'faraday'
require 'rainbow'
require 'addressable'

require 'zoho_hub/response'

module ZohoHub
  class Connection
    class << self
      def infer_api_domain
        case ZohoHub.configuration.api_domain
        when 'https://accounts.zoho.com'    then 'https://www.zohoapis.com'
        when 'https://accounts.zoho.com.cn' then 'https://www.zohoapis.com.cn'
        when 'https://accounts.zoho.in'     then 'https://www.zohoapis.in'
        when 'https://accounts.zoho.eu'     then 'https://www.zohoapis.eu'
        else DEFAULT_DOMAIN
        end
      end
    end

    attr_accessor :debug, :expires_in, :api_domain, :api_version, :refresh_token

    # This is a block to be run when the token is refreshed. This way you can do whatever you want
    # with the new parameters returned by the refresh method.
    attr_accessor :on_refresh_cb, :on_initialize_connection

    DEFAULT_DOMAIN = 'https://www.zohoapis.eu'

    BASE_PATH = '/crm/'

    SUPPORTED_HTTP_METHODS = %i[get post put delete].freeze
    SERVER_ERRORS = [500, 502, 503, 504].freeze

    def initialize(access_token: nil, api_domain: nil, api_version: nil, expires_in: 3600,
                   refresh_token: nil)
      @access_token = access_token
      @expires_in = expires_in
      @api_domain = api_domain || self.class.infer_api_domain
      @api_version = api_version || ZohoHub.configuration.api_version
      @refresh_token ||= refresh_token # do not overwrite if it's already set
      @mutex = Mutex.new
    end

    SUPPORTED_HTTP_METHODS.each do |method|
      define_method(method) do |path, params = {}|
        log "#{method.upcase} #{path} with #{params}"

        response = with_refresh { adapter.send(method, path, params) }
        raise ZohoHub::InternalError, response.body if SERVER_ERRORS.include?(response.env.status)

        response.body
      end
    end

    def access_token
      @access_token.respond_to?(:call) ? @access_token.call : @access_token
    end

    def access_token?
      @access_token
    end

    def refresh_token?
      @refresh_token
    end

    def log(text)
      return unless ZohoHub.configuration.debug?

      puts Rainbow("[ZohoHub] #{text}").magenta.bright
    end

    def refresh_token!
      was_locked = @mutex.locked?
      @mutex.synchronize do
        next if was_locked

        params = ZohoHub::Auth.refresh_token(@refresh_token)
        @on_refresh_cb.call(params) if @on_refresh_cb
        @access_token = params[:access_token] unless @access_token.respond_to?(:call)
      end
    end

    private

    def with_refresh(&block)
      http_response = with_authorization(&block)

      response = Response.new(http_response.body)

      # Try to refresh the token and try again
      if (response.invalid_token? || response.authentication_failure?) && refresh_token?
        log "Refreshing outdated token... #{@access_token}"
        refresh_token!

        http_response = with_authorization(&block)
      elsif response.authentication_failure?
        raise ZohoAPIError, response.msg
      end

      http_response
    end

    def with_authorization
      adapter.headers['Authorization'] = authorization if access_token?
      yield
    end

    def base_url
      Addressable::URI.join(api_domain, BASE_PATH, api_version).to_s
    end

    # The authorization header that must be added to every request for authorized requests.
    def authorization
      "Zoho-oauthtoken #{access_token}"
    end

    def adapter
      @adapter ||= Faraday.new(url: base_url) do |conn|
        conn.headers['Authorization'] = authorization if access_token?
        conn.request :json
        conn.response :json, parser_options: { symbolize_names: true }
        if ZohoHub.configuration.debug?
          conn.response :logger, ::Logger.new($stdout), headers: true, bodies: true
        end
        conn.adapter Faraday.default_adapter
        @on_initialize_connection.call(conn) if @on_initialize_connection
      end
    end
  end
end
