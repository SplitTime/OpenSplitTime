# frozen_string_literal: true

module Connectors
  Service = Struct.new(:identifier, :name, :credential_keys, keyword_init: true) do
    def self.all
      [
        new(
          identifier: "rattlesnake_ramble",
          name: "Rattlesnake Ramble",
          credential_keys: %w[email password]
        ),
        new(
          identifier: "runsignup",
          name: "RunSignup",
          credential_keys: %w[api_key api_secret]
        ),
      ]
    end

    self::BY_IDENTIFIER = all.index_by(&:identifier).with_indifferent_access
    self::IDENTIFIERS = self::BY_IDENTIFIER.keys
  end
end
