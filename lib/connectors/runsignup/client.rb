# frozen_string_literal: true

class Connectors::Runsignup::Client
  BASE_URL = "https://runsignup.com/Rest"
  RUNSIGNUP_ERROR_MAPPING = {
    7 => Connectors::Errors::NotAuthorized,
    201 => Connectors::Errors::NotFound,
    301 => Connectors::Errors::NotFound,
  }

  def initialize(user)
    @user = user
    verify_credentials_present!
  end

  def get_race(race_id)
    self.request = Connectors::Runsignup::Request::GetRace.new(race_id: race_id)
    make_request
  end

  def get_participants(race_id, event_id, page)
    self.request = Connectors::Runsignup::Request::GetParticipants.new(race_id: race_id, event_id: event_id, page: page)
    make_request
  end

  private

  attr_reader :user
  attr_accessor :request, :response

  # @return [String]
  def make_request
    self.response = ::RestClient.get(url, { params: params })
    check_response_validity!

    response.body
  end

  # @return [Hash]
  def params
    base_params.merge(request.specific_params)
  end

  # @return [String]
  def url
    BASE_URL + request.url_postfix
  end

  # @return [Hash]
  def base_params
    {
      api_key: runsignup_api_key,
      api_secret: runsignup_api_secret,
      format: :json,
    }
  end

  # @return [String, nil]
  def runsignup_api_key
    @runsignup_api_key ||= user.credentials.fetch("runsignup", "api_key")
  end

  # @return [String, nil]
  def runsignup_api_secret
    @runsignup_api_secret ||= user.credentials.fetch("runsignup", "api_secret")
  end

  def check_response_validity!
    case response.code
    when 401
      raise Connectors::Errors::NotAuthenticated
    when 403
      raise Connectors::Errors::NotAuthorized
    when 404
      raise Connectors::Errors::NotFound
    when 200
      if runsignup_error_code.present?
        if RUNSIGNUP_ERROR_MAPPING[runsignup_error_code].present?
          raise RUNSIGNUP_ERROR_MAPPING[runsignup_error_code], runsignup_error_message
        else
          raise Connectors::Errors::BadRequest, runsignup_error_message
        end
      end
    else
      raise Connectors::Errors::BadRequest, "#{response.code}: #{response.body}"
    end
  end

  # @return [Integer]
  def runsignup_error_code
    parsed_body.dig("error", "error_code")
  end

  def runsignup_error_message
    parsed_body.dig("error", "error_msg")
  end

  # @return [Hash, nil]
  def parsed_body
    return @parsed_body if defined?(@parsed_body)

    @parsed_body = JSON.parse(response.body)
    @parsed_body = @parsed_body.first if @parsed_body.is_a?(Array)
    @parsed_body
  end

  def verify_credentials_present!
    unless runsignup_api_key.present? && runsignup_api_secret.present?
      raise Connectors::Errors::MissingCredentials,
            "This source requires credentials for runsignup, but none were found."
    end
  end
end
