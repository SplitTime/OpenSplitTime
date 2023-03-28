# frozen_string_literal: true

module Connectors
  Service = Struct.new(:identifier, :name, :credentials, keyword_init: true) do
    def self.all
      [
        new(
          identifier: "runsignup",
          name: "RunSignup",
          credentials: %w[api_key api_secret]
        )
      ]
    end

    self::BY_IDENTIFIER = all.index_by(&:identifier).with_indifferent_access
    self::IDENTIFIERS = self::BY_IDENTIFIER.keys
  end
end
