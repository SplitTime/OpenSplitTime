# frozen_string_literal: true

class SyncableRelationParameters < BaseParameters
  def self.permitted
    [
      :source_name,
      :source_id,
    ]
  end
end
