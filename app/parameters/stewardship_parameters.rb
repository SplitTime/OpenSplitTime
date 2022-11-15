# frozen_string_literal: true

class StewardshipParameters < BaseParameters
  def self.permitted
    [
      :level
    ]
  end
end
