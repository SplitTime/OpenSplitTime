VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i.freeze
VALID_PHONE_REGEX = /\A\+?\d+\z/.freeze

module OST
  BASE_URI = ENV["BASE_URI"]
  SHORTENED_URI = ENV["SHORTENED_URI"] || BASE_URI
end
