# frozen_string_literal: true

class ImportJobParameters < BaseParameters
  def self.permitted
    [
      :files,
      :format,
      :parent_id,
      :parent_type
    ]
  end
end
