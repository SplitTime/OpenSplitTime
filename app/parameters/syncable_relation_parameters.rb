# frozen_string_literal: true

class SyncableRelationParameters < BaseParameters
  def self.permitted
    [
      :source_name,
      :source_type,
      :source_id,
      :destination_name,
      :destination_type,
      :destination_id,
    ]
  end
end
