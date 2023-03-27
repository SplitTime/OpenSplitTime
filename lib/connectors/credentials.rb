# frozen_string_literal: true

module Connectors
  Credentials = Struct.new(:name, :credentials, keyword_init: true) do
    def self.all
      [
        new(
          name: "RunSignup",
          credentials: [:api_key, :api_secret]
        )
      ]
    end
  end
end
