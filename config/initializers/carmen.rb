# Patch Carmen::Querying to avoid deprecated String#mb_chars (removed in Rails 8.2).
# Modern Ruby's String#downcase handles Unicode correctly without mb_chars.
module Carmen
  module Querying
    private

    def normalise_name(name)
      name.downcase.unicode_normalize(:nfkc)
    end
  end
end
