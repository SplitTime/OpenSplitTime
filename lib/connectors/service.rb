# frozen_string_literal: true

module Connectors
  Service = Struct.new(:identifier, :name, :credentials, keyword_init: true) do
    def self.all
      [
        new(
          identifier: :runsignup,
          name: "RunSignup",
          credentials: [:api_key, :api_secret]
        )
      ]
    end

    self::IDENTIFIERS = all.map { |service| service.identifier.to_s }
  end
end
