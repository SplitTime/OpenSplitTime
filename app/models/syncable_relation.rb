# frozen_string_literal: true

class SyncableRelation < ApplicationRecord
  belongs_to :destination, polymorphic: true

  scope :to_destination, ->(destination_name) { where(destination_name: destination_name) }
  scope :from_source, ->(source_name) { where(source_name: source_name) }
end
