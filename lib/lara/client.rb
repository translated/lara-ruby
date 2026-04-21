# frozen_string_literal: true

require "faraday"
require "faraday/multipart"
require "json"
require "openssl"
require "base64"
require "digest"
require "uri"
require "monitor"

module Lara
  # This class is used to interact with Lara via the REST API.

  class Client
    DEFAULT_BASE_URL = "https://api.laratranslate.com"

    def initialize(auth_method, base_url: DEFAULT_BASE_URL, connection_timeout: nil,
                   read_timeout: nil)
      case auth_method
      when Credentials
        @credentials = auth_method
        @auth_token = nil
      when AuthToken
        @credentials = nil
        @auth_token = auth_method
      else
        raise ArgumentError, "auth_method must be Credentials or AuthToken"
      end

      @base_url = base_url.to_s.sub(%r{/+$}, "")
      @connection_timeout = connection_timeout
      @read_timeout = read_timeout
      @extra_headers = {}
      @auth_mutex = Monitor.new

      @connection = build_connection
    end

    attr_reader :base_url

    # Sets an extra header
    # @param name [String] Header name
    # @param value [String] Header value
    def set_extra_header(name, value)
      @extra_headers[name] = value
    end

    # Sends a GET request to the Lara API.
    # @param path [String] The path to send the request to.
    # @param params [Hash,nil] The parameters to send with the request.
    # @param headers [Hash,nil] Additional headers to include in the request.
    # @return [Hash, Array, String, nil] The JSON 'content' from the API or CSV body for csv responses.
    def get(path, params: nil, headers: nil)
      request(:get, path, body: nil, headers: headers, params: params)
    end

    # Sends a POST request to the Lara API.
    # @param path [String] The path to send the request to.
    # @param body [Hash,nil] The parameters to send with the request.
    # @param files [Hash,nil] The files to send with the request. If present, request will be sent as multipart/form-data.
    # @param headers [Hash,nil] Additional headers to include in the request.
    # @param raw_response [Boolean] If true, returns the raw response body (useful for binary data like images).
    # @yield [Hash] Each partial JSON result from the stream (if streaming)
    # @return [Hash, Array, String, nil] The JSON 'content' from the API, CSV body, or raw bytes.
    def post(path, body: nil, files: nil, headers: nil, raw_response: false, &callback)
      request(:post, path, body: body, files: files, headers: headers, raw_response: raw_response, &callback)
    end

    # Sends a PUT request to the Lara API.
    # @param path [String] The path to send the request to.
    # @param body [Hash,nil] The parameters to send with the request.
    # @param files [Hash,nil] The files to send with the request. If present, request will be sent as multipart/form-data.
    # @param headers [Hash,nil] Additional headers to include in the request.
    # @return [Hash, Array, String, nil] The JSON 'content' from the API or CSV body for csv responses.
    def put(path, body: nil, files: nil, headers: nil)
      request(:put, path, body: body, files: files, headers: headers)
    end

    # Sends a DELETE request to the Lara API.
    # @param path [String] The path to send the request to.
    # @param params [Hash,nil] The parameters to send with the request.
    # @param headers [Hash,nil] Additional headers to include in the request.
    # @return [Hash, Array, String, nil] The JSON 'content' from the API or CSV body for csv responses.
    def delete(path, params: nil, body: nil, headers: nil)
      request(:delete, path, body: body, headers: headers, params: params)
    end

    private

    def request(method, path, body: nil, files: nil, headers: nil, params: nil, raw_response: false, &callback)
      ensure_valid_token

      make_request(method, path, body: body, files: files, headers: headers, params: params,
                   raw_response: raw_response, &callback)
    rescue LaraApiError => e
      raise unless e.status_code == 401

      @auth_mutex.synchronize { refresh_or_reauthenticate }
      make_request(method, path, body: body, files: files, headers: headers, params: params,
                   raw_response: raw_response, &callback)
    end

    def ensure_valid_token
      @auth_mutex.synchronize do
        return if @auth_token && !@auth_token.token_expired?

        refresh_or_reauthenticate
      end
    end

    def refresh_or_reauthenticate
      if @auth_token&.refresh_token && !@auth_token.refresh_token.empty?
        begin
          do_refresh
          return
        rescue StandardError
          raise unless @credentials
        end
      end

      if @credentials
        @auth_token = authenticate
        return
      end

      raise LaraError, "No authentication method available for token renewal"
    end

    def authenticate
      path = "/v2/auth"
      method = "POST"
      timestamp = Time.now.utc.strftime("%a, %d %b %Y %H:%M:%S GMT")

      body = { id: @credentials&.access_key_id }
      body_json = body.to_json
      content_md5 = Digest::MD5.hexdigest(body_json)

      headers = {
        "Date" => timestamp,
        "X-Lara-SDK-Name" => "lara-ruby",
        "X-Lara-SDK-Version" => Lara::VERSION,
        "Content-Type" => "application/json",
        "Content-MD5" => content_md5,
        "Authorization" => "Lara:#{generate_hmac_signature(method, path, content_md5,
                                                           'application/json', timestamp)}"
      }

      conn = Faraday.new(url: @base_url) do |c|
        c.adapter Faraday.default_adapter
      end

      response = conn.post(path) do |req|
        req.headers = headers
        req.body = body_json
      end

      raise LaraApiError.from_response(response) unless response.success?

      data = JSON.parse(response.body)
      refresh_token_value = response.headers["x-lara-refresh-token"]

      raise LaraError, "Missing refresh token in authentication response" unless refresh_token_value

      AuthToken.new(data["token"], refresh_token_value)
    end

    def do_refresh
      raise LaraError, "No refresh token available" unless @auth_token&.refresh_token

      conn = Faraday.new(url: @base_url) do |c|
        c.adapter Faraday.default_adapter
      end

      response = conn.post("/v2/auth/refresh") do |req|
        req.headers = {
          "Date" => Time.now.utc.strftime("%a, %d %b %Y %H:%M:%S GMT"),
          "X-Lara-SDK-Name" => "lara-ruby",
          "X-Lara-SDK-Version" => Lara::VERSION,
          "Authorization" => "Bearer #{@auth_token.refresh_token}"
        }
      end

      raise LaraApiError.from_response(response) unless response.success?

      data = JSON.parse(response.body)
      refresh_token_value = response.headers["x-lara-refresh-token"]

      raise LaraError, "Missing refresh token in refresh response" unless refresh_token_value

      @auth_token = AuthToken.new(data["token"], refresh_token_value)
    end

    def make_request(method, path, body: nil, files: nil, headers: nil, params: nil, raw_response: false, &callback)
      path = "/#{path}" unless path.start_with?("/")
      request_headers = build_request_headers(body, files, headers)

      # Make the API call
      response = if files&.any?
                   @connection.post(path) do |req|
                     req.headers.merge!(request_headers)
                     req.params = params if params
                     req.body = body.is_a?(Hash) ? body.dup : {}
                     files.each { |key, value| req.body[key] = value }
                   end
                 else
                   @connection.send(method, path) do |req|
                     req.headers.merge!(request_headers)
                     req.params = params if params
                     req.body = body.to_json if body.is_a?(Hash) && !body.empty?
                   end
                 end

      raise LaraApiError.from_response(response) unless response.success?

      return response.body if raw_response

      content_type = response.headers["content-type"] || response.headers["Content-Type"]
      return response.body if content_type&.include?("text/csv")

      if callback || (body && body[:reasoning])
        parse_stream_response(response.body, &callback)
      else
        parse_json(response.body)
      end
    end

    def parse_json(body)
      return {} if body.nil? || body.empty?

      parsed = JSON.parse(body)
      if parsed.is_a?(Hash) && parsed.key?("content")
        inner = parsed["content"]
        return inner if inner.is_a?(Hash) || inner.is_a?(Array)
      end
      parsed
    end

    def parse_stream_response(body, &block)
      return {} if body.nil? || body.empty?

      buffer = ""
      last_result = nil

      body.each_line do |line|
        buffer += line
        next unless line.end_with?("\n")

        trimmed_line = buffer.strip
        buffer = ""

        next if trimmed_line.empty?

        begin
          parsed = JSON.parse(trimmed_line)
          result = parsed["content"] || parsed
          block.call(result) if block
          last_result = result
        rescue JSON::ParserError
          next
        end
      end

      if !buffer.empty? && buffer.strip != ""
        begin
          parsed = JSON.parse(buffer.strip)
          result = parsed["content"] || parsed
          block.call(result) if block
          last_result = result
        rescue JSON::ParserError
        end
      end

      last_result || {}
    end

    def build_request_headers(body, files, extra_headers)
      timestamp = Time.now.utc.strftime("%a, %d %b %Y %H:%M:%S GMT")

      headers = {
        "Date" => timestamp,
        "X-Lara-SDK-Name" => "lara-ruby",
        "X-Lara-SDK-Version" => Lara::VERSION,
        "Authorization" => "Bearer #{@auth_token&.token}",
        **@extra_headers
      }

      headers.merge!(extra_headers) if extra_headers

      if !files&.any? && body.is_a?(Hash) && !body.empty?
        headers["Content-Type"] = "application/json"
      end

      headers
    end

    def build_connection
      Faraday.new(url: @base_url) do |conn|
        conn.request :multipart
        conn.request :url_encoded
        conn.adapter Faraday.default_adapter
        conn.options.timeout = @connection_timeout if @connection_timeout
        conn.options.open_timeout = @read_timeout if @read_timeout
      end
    end

    def generate_hmac_signature(method, path, content_md5, content_type, timestamp)
      string_to_sign = [
        method.to_s.upcase,
        path,
        content_md5,
        content_type,
        timestamp
      ].join("\n")

      digest = OpenSSL::HMAC.digest("sha256", @credentials&.access_key_secret || "", string_to_sign)
      Base64.strict_encode64(digest)
    end
  end
end
