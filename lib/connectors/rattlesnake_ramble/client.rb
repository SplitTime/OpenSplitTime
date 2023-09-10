# frozen_string_literal: true

class Connectors::RattlesnakeRamble::Client
  BASE_URL = "https://www.rattlesnakeramble.org"

  def initialize(user)
    @user = user
    verify_credentials_present!
  end

  def get_race_editions
    self.request = Connectors::RattlesnakeRamble::Request::GetRaceEditions.new
    make_request
  end

  def get_race_edition(race_edition_id)
    self.request = Connectors::RattlesnakeRamble::Request::GetRaceEdition.new(race_edition_id: race_edition_id)
    make_request
  end

  private

  attr_reader :user
  attr_accessor :request, :response, :response_code, :raw_error_message

  # @return [String]
  def make_request
    self.response = ::RestClient.get(url, { params: params })
    self.response_code = response.code

    response.body
  rescue RestClient::Exception => e
    self.response_code = e.http_code
    self.raw_error_message = e.message
  ensure
    check_response_validity!
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
      user: {
        email: ramble_email,
        password: ramble_password,
      },
      format: :json,
    }
  end

  # @return [String, nil]
  def ramble_email
    @ramble_email ||= user.credentials.fetch("rattlesnake_ramble", "email")
  end

  # @return [String, nil]
  def ramble_password
    @ramble_password ||= user.credentials.fetch("rattlesnake_ramble", "password")
  end

  def check_response_validity!
    case response_code
    when 401
      raise Connectors::Errors::NotAuthenticated, "Credentials were not accepted"
    when 403
      raise Connectors::Errors::NotAuthorized, "Access is not authorized"
    when 404
      raise Connectors::Errors::NotFound, "Resource not found"
    when 200
    else
      raise Connectors::Errors::BadRequest, "#{response_code}: #{raw_error_message}"
    end
  end

  # @return [Hash, nil]
  def parsed_body
    return @parsed_body if defined?(@parsed_body)

    @parsed_body = JSON.parse(response.body)
  end

  def verify_credentials_present!
    unless ramble_email.present? && ramble_password.present?
      raise Connectors::Errors::MissingCredentials,
            "This source requires credentials for rattlesnake_ramble, but none were found."
    end
  end
end
